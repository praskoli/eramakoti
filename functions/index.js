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

    // Idempotent write: set same document id
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

    // Run only when status changes to verified
    if (beforeData.status === "verified" || afterData.status !== "verified") {
      return;
    }

    const donationId = event.params.donationId;
    const uid = event.params.uid;

    const anonymous = afterData.anonymous === true;
    const rawName =
      (afterData.supporterName || afterData.userDisplayName || "").trim();

    const name = anonymous
      ? "Anonymous"
      : (rawName || "Devotee");

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
        source: "ramakoti_app",
        timestamp: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
);