class AuthErrorHandler {
  static String getFirebaseAuthErrorMessage(String errorCode) {
    print('🔍 AuthErrorHandler received code: "$errorCode"');
    
    switch (errorCode) {
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password. Please try again';
      case 'invalid-credential': // ADD THIS CASE - this is the key fix!
        return 'Incorrect email or password. Please check your credentials';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'network-request-failed':
        return 'Check your internet connection';
      case 'requires-recent-login':
        return 'Please sign in again to continue';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'invalid-verification-id':
        return 'Invalid verification ID';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled';
      case 'user-mismatch':
        return 'This credential does not match the signed-in user';
      case 'invalid-verification':
        return 'Invalid verification';
      default:
        print('⚠️ Unhandled Firebase error code: "$errorCode"');
        return 'An error occurred. Please try again';
    }
  }

  static String getGenericErrorMessage(dynamic error) {
    print('🔍 Generic error: $error');
    
    if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please try again';
    } else if (error.toString().contains('[firebase_auth/')) {
      // Try to extract Firebase error code from string
      final match = RegExp(r'\[firebase_auth/([^\]]+)\]').firstMatch(error.toString());
      if (match != null && match.groupCount >= 1) {
        final extractedCode = match.group(1);
        return getFirebaseAuthErrorMessage(extractedCode!);
      }
      return 'Authentication failed. Please try again';
    } else {
      return 'Something went wrong. Please try again';
    }
  }
}