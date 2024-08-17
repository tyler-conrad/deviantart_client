/// Represents an API error.
///
/// An [APIError] object contains information about an error that occurred during an API request.
class APIError {
  /// The error message.
  final String error;

  /// The error description.
  final String desc;

  /// Additional details about the error.
  final Map<String, dynamic> details;

  /// The error code.
  final int? code;

  /// Creates a new instance of [APIError].
  ///
  /// The [error], [desc], and [details] parameters are required.
  /// The [code] parameter is optional.
  const APIError({
    required this.error,
    required this.desc,
    required this.details,
    this.code,
  });

  /// Creates a new instance of [APIError] from a JSON object.
  ///
  /// The [decoded] parameter is a JSON object that contains the error information.
  factory APIError.fromJSON({required Map<String, dynamic> decoded}) {
    return APIError(
        error: decoded['error'],
        desc: decoded['error_description'],
        details: decoded['error_details'] ?? {},
        code: decoded['error_code']);
  }
}
