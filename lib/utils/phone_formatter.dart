/// Utility class for phone number formatting
class PhoneNumberFormatter {
  /// Formats Egyptian phone numbers to international E.164 format
  ///
  /// Egyptian numbers can be:
  /// - 01XXXXXXXXX (11 digits starting with 0)
  /// - +201XXXXXXXXX (international format)
  /// - 201XXXXXXXXX (without +)
  ///
  /// Returns the formatted number in E.164 format (+20XXXXXXXXXX) or null if invalid
  static String? formatEgyptianNumber(String input) {
    // Remove all non-digit characters except +
    String cleanNumber = input.replaceAll(RegExp(r'[^\d+]'), '');

    // If it starts with +20, it's already in international format
    if (cleanNumber.startsWith('+20')) {
      if (cleanNumber.length == 13) {
        // +20 + 10 digits
        return cleanNumber;
      }
      return null; // Invalid length
    }

    // If it starts with 20 (without +), add +
    if (cleanNumber.startsWith('20')) {
      if (cleanNumber.length == 12) {
        // 20 + 10 digits
        return '+$cleanNumber';
      }
      return null; // Invalid length
    }

    // If it starts with 0, remove the 0 and add +20
    if (cleanNumber.startsWith('0')) {
      if (cleanNumber.length == 11) {
        // 0 + 10 digits
        String numberWithoutZero = cleanNumber.substring(1);
        return '+20$numberWithoutZero';
      }
      return null; // Invalid length
    }

    // If it starts with 1, assume it's without country code
    if (cleanNumber.startsWith('1')) {
      if (cleanNumber.length == 10) {
        // 10 digits for Egyptian mobile
        return '+20$cleanNumber';
      }
      return null; // Invalid length
    }

    // If it's just 10 digits without any prefix
    if (cleanNumber.length == 10 &&
        RegExp(r'^[1]\d{9}$').hasMatch(cleanNumber)) {
      return '+20$cleanNumber';
    }

    // If it's 11 digits without 0 at the beginning
    if (cleanNumber.length == 11 && cleanNumber.startsWith('1')) {
      return '+20${cleanNumber.substring(1)}';
    }

    return null; // Invalid format
  }

  /// Validates if the input is a valid Egyptian phone number
  static bool isValidEgyptianNumber(String input) {
    String? formatted = formatEgyptianNumber(input);
    return formatted != null;
  }

  /// Validates the length of an Egyptian mobile number
  static bool isValidEgyptianMobileLength(String number) {
    String cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanNumber.startsWith('+20')) {
      return cleanNumber.length == 13;
    } else if (cleanNumber.startsWith('20')) {
      return cleanNumber.length == 12;
    } else if (cleanNumber.startsWith('0')) {
      return cleanNumber.length == 11;
    } else if (cleanNumber.startsWith('1')) {
      return cleanNumber.length == 10;
    }
    return false;
  }
}
