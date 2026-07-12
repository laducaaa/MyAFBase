package com.ryanladuca.myafbase.utils

object ContactConfig {
    const val SUPPORT_EMAIL = "support@myafbase.com"
    const val LEGAL_EMAIL = "legal@myafbase.com"
    const val WEBSITE_URL = "https://myafbase.com"
    const val SUPPORT_URL = "https://myafbase.com/support"
    const val PRIVACY_URL = "https://myafbase.com/privacy"
    const val USER_CHOICES_URL = "https://myafbase.com/user-choices"
    const val TERMS_URL = "https://myafbase.com/terms"

    val supportMailtoUrl: String get() = "mailto:$SUPPORT_EMAIL"
    val legalMailtoUrl: String get() = "mailto:$LEGAL_EMAIL"
}
