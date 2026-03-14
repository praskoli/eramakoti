const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();

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
