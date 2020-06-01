@file:JvmName("MimeTypeExt")

package com.sangcomz.fishbun.util

import com.sangcomz.fishbun.MimeType

fun MimeType.equalsMimeType(mimeType: String) = this.type == mimeType