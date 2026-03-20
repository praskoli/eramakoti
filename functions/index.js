const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const crypto = require("crypto");
const Razorpay = require("razorpay");

initializeApp();

const db = getFirestore();

const razorpayKeyId = defineSecret("RAZORPAY_KEY_ID");
const razorpayKeySecret = defineSecret("RAZORPAY_KEY_SECRET");

function getRazorpayClient() {
  return new Razorpay({
    key_id: razorpayKeyId.value(),
    key_secret: razorpayKeySecret.value(),
  });
}

function cleanString(value) {
  return String(value || "").trim();
}

function safeNumber(value, fallback = 0) {
  const num = Number(value);
  return Number.isFinite(num) ? num : fallback;
}

exports.mirrorDonationToAdmin = onDocumentCreated(
  "users/{uid}/donations/{donationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const donationId = event.params.donationId;

    const adminRef = db.collection("admin_donations").doc(donationId);

    await adminRef.set(
      {
        ...data,
        mirroredFrom: `users/${event.params.uid}/donations/${donationId}`,
        mirroredAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
);

exports.syncDonationUpdateToAdmin = onDocumentUpdated(
  "users/{uid}/donations/{donationId}",
  async (event) => {
    const after = event.data.after;
    if (!after) return;

    const data = after.data();
    const donationId = event.params.donationId;

    const adminRef = db.collection("admin_donations").doc(donationId);

    await adminRef.set(
      {
        ...data,
        mirroredFrom: `users/${event.params.uid}/donations/${donationId}`,
        mirroredAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
);

exports.createSupportWallOnVerifiedDonation = onDocumentUpdated(
  "users/{uid}/donations/{donationId}",
  async (event) => {
    const before = event.data.before;
    const after = event.data.after;

    if (!before || !after) return;

    const beforeData = before.data();
    const afterData = after.data();

    if (beforeData.status === "verified" || afterData.status !== "verified") {
      return;
    }

    const donationId = event.params.donationId;
    const uid = event.params.uid;

    const anonymous = afterData.anonymous === true;
    const rawName = (afterData.supporterName || afterData.userDisplayName || "").trim();
    const name = anonymous ? "Anonymous" : (rawName || "Devotee");

    const wallRef = db.collection("support_wall").doc(donationId);

    await wallRef.set(
      {
        donationId,
        uid,
        name,
        amount: afterData.amount || 0,
        message: (afterData.supporterMessage || "").trim(),
        anonymous,
        verified: true,
        source: afterData.supportType === "mandali" ? "mandali_support" : "ramakoti_app",
        supportType: afterData.supportType || "individual",
        sourceMandaliId: afterData.sourceMandaliId || null,
        sourceMandaliName: afterData.sourceMandaliName || null,
        sourceChallengeId: afterData.sourceChallengeId || null,
        timestamp: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
);

exports.syncMandaliChallengeSummary = onDocumentUpdated(
  "bhaktaMandalis/{mandaliId}/challenges/{challengeId}",
  async (event) => {
    const beforeSnap = event.data.before;
    const afterSnap = event.data.after;
    if (!beforeSnap || !afterSnap) return;

    const before = beforeSnap.data() || {};
    const after = afterSnap.data() || {};
    const mandaliId = event.params.mandaliId;
    const challengeId = event.params.challengeId;
    const mandaliRef = db.collection("bhaktaMandalis").doc(mandaliId);

    const target = Number(after.target || after.targetCount || 0);
    const progress = Number(after.progressCount || 0);
    const afterCompleted = after.status === "completed" || (target > 0 && progress >= target);
    const completedAt = after.completedAt || (afterCompleted ? FieldValue.serverTimestamp() : null);

    await mandaliRef.set(
      {
        activeChallengeId: challengeId,
        activeChallenge: {
          challengeId,
          title: after.title || after.challengeName || "Mandali Challenge",
          target,
          progressCount: progress,
          status: afterCompleted ? "completed" : (after.status || "active"),
          createdAt: after.createdAt || null,
          startDate: after.startDate || null,
          endDate: after.endDate || null,
          completedAt,
          updatedAt: FieldValue.serverTimestamp(),
        },
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const beforeCompleted = before.status === "completed";
    if (!beforeCompleted && afterCompleted) {
      await afterSnap.ref.set(
        {
          status: "completed",
          completedAt,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }
  }
);

exports.generateMandaliCertificates = onDocumentUpdated(
  "bhaktaMandalis/{mandaliId}/challenges/{challengeId}",
  async (event) => {
    const beforeSnap = event.data.before;
    const afterSnap = event.data.after;
    if (!beforeSnap || !afterSnap) return;

    const before = beforeSnap.data() || {};
    const after = afterSnap.data() || {};
    const beforeCompleted = before.status === "completed";
    const afterCompleted = after.status === "completed";
    if (beforeCompleted || !afterCompleted) return;

    const mandaliId = event.params.mandaliId;
    const challengeId = event.params.challengeId;

    const mandaliRef = db.collection("bhaktaMandalis").doc(mandaliId);
    const mandaliSnap = await mandaliRef.get();
    if (!mandaliSnap.exists) return;
    const mandali = mandaliSnap.data() || {};

    const mandaliName = String(mandali.displayName || mandali.name || "Bhakta Mandali");
    const challengeName = String(after.title || after.challengeName || "Mandali Challenge");
    const targetCount = Number(after.target || after.targetCount || 0);

    const membersSnap = await mandaliRef.collection("members").get();

    const now = new Date();
    const yyyy = String(now.getUTCFullYear());
    const mm = String(now.getUTCMonth() + 1).padStart(2, "0");
    const dd = String(now.getUTCDate()).padStart(2, "0");

    const batch = db.batch();
    let recipientCount = 0;

    for (const memberDoc of membersSnap.docs) {
      const member = memberDoc.data() || {};
      const contributionCount = Number(member.challengeContributionCount || 0);
      if (contributionCount < 1) continue;

      const certificateRef = mandaliRef.collection("certificates").doc();
      const certificateId = certificateRef.id;
      const uid = String(member.uid || memberDoc.id);
      const storagePath = `mandaliCertificates/${yyyy}/${mm}/${dd}/${mandaliId}/${certificateId}.pdf`;

      batch.set(certificateRef, {
        certificateId,
        type: "mandali",
        uid,
        displayName: String(member.displayName || "Devotee"),
        mandaliId,
        mandaliName,
        challengeId,
        challengeName,
        contributionCount,
        targetCount,
        completedAt: after.completedAt || FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
        storagePath,
        downloadUrl: null,
        status: "ready_for_pdf",
      });

      recipientCount += 1;
    }

    if (recipientCount > 0) {
      await batch.commit();
    }

    await mandaliRef.set(
      {
        lastCertificateRunAt: FieldValue.serverTimestamp(),
        lastCertificateChallengeId: challengeId,
        lastCertificateAwardCount: recipientCount,
      },
      { merge: true }
    );
  }
);

/**
 * NEW: Create Razorpay order safely on backend.
 * This does not affect your current live donation flow until the app starts calling it.
 */
exports.createRazorpayOrder = onCall(
  {
    region: "asia-south1",
    secrets: [razorpayKeyId, razorpayKeySecret],
  },
  async (request) => {
    console.log("createRazorpayOrder auth =", request.auth);
    console.log("createRazorpayOrder app =", request.app);
    console.log("createRazorpayOrder data =", request.data);

    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const data = request.data || {};
    const uid = request.auth.uid;

    const amount = safeNumber(data.amount, 0);
    if (!Number.isInteger(amount) || amount < 1) {
      throw new HttpsError("invalid-argument", "Amount must be an integer >= 1.");
    }

    const source = cleanString(data.source) || "support_screen";
    const supportType = cleanString(data.supportType) || "individual";
    const supporterName = cleanString(data.supporterName);
    const supporterMessage = cleanString(data.supporterMessage);
    const anonymous = data.anonymous === true;

    const sourceMandaliId = cleanString(data.sourceMandaliId) || null;
    const sourceMandaliName = cleanString(data.sourceMandaliName) || null;
    const sourceChallengeId = cleanString(data.sourceChallengeId) || null;

    const donationRef = db.collection("users").doc(uid).collection("donations").doc();
    const donationId = donationRef.id;
    const receipt = `don_${donationId}`.slice(0, 40);

    const razorpay = getRazorpayClient();

    let order;
    try {
      order = await razorpay.orders.create({
        amount: amount * 100,
        currency: "INR",
        receipt,
        notes: {
          donationId,
          uid,
          source,
          supportType,
          sourceMandaliId: sourceMandaliId || "",
          sourceMandaliName: sourceMandaliName || "",
          sourceChallengeId: sourceChallengeId || "",
        },
      });
    } catch (error) {
      console.error("Razorpay order creation failed:", error);
      throw new HttpsError("internal", "Could not create Razorpay order.");
    }

    await donationRef.set({
      donationId,
      uid,
      amount,
      currency: "INR",
      source,
      supportType,
      sourceMandaliId,
      sourceMandaliName,
      sourceChallengeId,
      userDisplayName: cleanString(request.auth.token.name || ""),
      supporterName,
      supporterMessage,
      anonymous,
      paymentProvider: "razorpay",
      paymentMode: "checkout",
      status: "created",
      razorpayOrderId: order.id,
      razorpayPaymentId: null,
      razorpaySignature: null,
      razorpayOrderStatus: order.status || "created",
      verifiedAt: null,
      paidAt: null,
      failureReason: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      donationId,
      orderId: order.id,
      amount: amount * 100,
      currency: "INR",
      razorpayKeyId: razorpayKeyId.value(),
      name: "eRamakoti",
      description: supportType === "mandali" ? "Mandali Support" : "Offer Support",
      prefill: {
        name: supporterName || cleanString(request.auth.token.name || ""),
        email: cleanString(request.auth.token.email || ""),
        contact: cleanString(request.auth.token.phone_number || ""),
      },
      notes: {
        donationId,
        supportType,
        source,
      },
    };
  }
);

/**
 * NEW: Verify Razorpay payment signature on backend and finalize donation state.
 */
exports.verifyRazorpayPayment = onCall(
  {
    region: "asia-south1",
    secrets: [razorpayKeyId, razorpayKeySecret],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const data = request.data || {};
    const uid = request.auth.uid;

    const donationId = cleanString(data.donationId);
    const razorpayOrderId = cleanString(data.razorpayOrderId);
    const razorpayPaymentId = cleanString(data.razorpayPaymentId);
    const razorpaySignature = cleanString(data.razorpaySignature);

    if (!donationId || !razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      throw new HttpsError("invalid-argument", "Missing payment verification fields.");
    }

    const donationRef = db.collection("users").doc(uid).collection("donations").doc(donationId);
    const donationSnap = await donationRef.get();

    if (!donationSnap.exists) {
      throw new HttpsError("not-found", "Donation record not found.");
    }

    const donation = donationSnap.data() || {};
    if (donation.uid !== uid) {
      throw new HttpsError("permission-denied", "Donation does not belong to current user.");
    }

    if (cleanString(donation.razorpayOrderId) !== razorpayOrderId) {
      throw new HttpsError("failed-precondition", "Order ID mismatch.");
    }

    const expectedSignature = crypto
      .createHmac("sha256", razorpayKeySecret.value())
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest("hex");

    if (expectedSignature !== razorpaySignature) {
      await donationRef.set(
        {
          status: "verification_failed",
          razorpayPaymentId,
          razorpaySignature,
          failureReason: "signature_mismatch",
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      throw new HttpsError("permission-denied", "Payment signature verification failed.");
    }

    await donationRef.set(
      {
        status: "verified",
        razorpayPaymentId,
        razorpaySignature,
        verifiedAt: FieldValue.serverTimestamp(),
        paidAt: FieldValue.serverTimestamp(),
        failureReason: null,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return {
      success: true,
      donationId,
      status: "verified",
    };
  }
);

/**
 * NEW: Mark cancelled/failed checkout attempts without affecting current live flow.
 * Optional but useful for history and support UX.
 */
exports.markRazorpayPaymentFailed = onCall(
  {
    region: "asia-south1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const data = request.data || {};
    const uid = request.auth.uid;

    const donationId = cleanString(data.donationId);
    const reason = cleanString(data.reason) || "checkout_failed";

    if (!donationId) {
      throw new HttpsError("invalid-argument", "Missing donationId.");
    }

    const donationRef = db.collection("users").doc(uid).collection("donations").doc(donationId);
    const donationSnap = await donationRef.get();

    if (!donationSnap.exists) {
      throw new HttpsError("not-found", "Donation record not found.");
    }

    const donation = donationSnap.data() || {};
    if (donation.uid !== uid) {
      throw new HttpsError("permission-denied", "Donation does not belong to current user.");
    }

    await donationRef.set(
      {
        status: "failed",
        failureReason: reason,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return {
      success: true,
      donationId,
      status: "failed",
    };
  }
);