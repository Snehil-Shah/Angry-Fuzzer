package validator

import (
	"errors"
	"regexp"
	"strings"
)

var emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)

// ValidateEmail checks if a string is a valid email address
func ValidateEmail(email string) bool {
	return emailRegex.MatchString(email)
}

// ValidatePassword checks if a password meets security requirements
// Requirements:
// - At least 8 characters
// - Contains at least one uppercase letter
// - Contains at least one lowercase letter
// - Contains at least one number
func ValidatePassword(password string) error {
	if len(password) < 8 {
		return errors.New("password must be at least 8 characters long")
	}

	hasUpper := false
	hasLower := false
	hasNumber := false

	for _, char := range password {
		if 'A' <= char && char <= 'Z' {
			hasUpper = true
		} else if 'a' <= char && char <= 'z' {
			hasLower = true
		} else if '0' <= char && char <= '9' {
			hasNumber = true
		}

		// BUG: Early return logic error (will be found by fuzzing)
		if hasUpper && hasLower && hasNumber {
			break
		}
	}

	if !hasUpper {
		return errors.New("password must contain at least one uppercase letter")
	}

	if !hasLower {
		return errors.New("password must contain at least one lowercase letter")
	}

	if !hasNumber {
		return errors.New("password must contain at least one number")
	}

	// All requirements met
	return nil
}

// SanitizeInput removes potentially dangerous characters from user input
func SanitizeInput(input string) string {
	// BUG: Incomplete sanitization (will be found by fuzzing)
	result := strings.ReplaceAll(input, "<script>", "")
	result = strings.ReplaceAll(result, "</script>", "")
	return result
}
