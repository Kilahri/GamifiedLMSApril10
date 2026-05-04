// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.adminUpdateUserPassword = functions.https.onCall(async (data, context) => {
  // 1. Verify caller is admin
  const caller = await admin.firestore()
    .collection('users').doc(context.auth.uid).get();
  if (caller.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Admins only.');
  }

  // 2. Update Firebase Auth password
  await admin.auth().updateUser(data.uid, { password: data.newPassword });

  // 3. Update stored password in Firestore
  await admin.firestore()
    .collection('users').doc(data.uid)
    .update({ password: data.newPassword });

  return { success: true };
});