/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import 'dart:html' as html;

/// Web implementation for XSRF token retrieval.
String? retrieveXsrfTokenImpl() {
  final cookies = html.document.cookie ?? '';
  final match = RegExp(r'(^|;\s*)(XSRF-TOKEN)=([^;]*)').firstMatch(cookies);
  return match != null ? Uri.decodeComponent(match.group(3)!) : null;
}


