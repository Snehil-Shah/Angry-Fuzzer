package validator

import (
	"testing"
)

func TestValidateEmail(t *testing.T) {
	tests := []struct {
		name  string
		email string
		want  bool
	}{
		{"valid email", "test@example.com", true},
		{"invalid email - no @", "testexample.com", false},
		{"invalid email - no domain", "test@", false},
		{"invalid email - no username", "@example.com", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := ValidateEmail(tt.email); got != tt.want {
				t.Errorf("ValidateEmail() = %v, want %v", got, tt.want)
			}
		})
	}
}

func FuzzValidateEmail(f *testing.F) {
	// Seed corpus
	f.Add("user@example.com")
	f.Add("test.name@domain.co.uk")
	f.Add("") // Empty string

	f.Fuzz(func(t *testing.T, email string) {
		// Just ensure the function doesn't panic
		_ = ValidateEmail(email)
	})
}

func FuzzValidatePassword(f *testing.F) {
	// Seed corpus
	f.Add("Password123")
	f.Add("weak")
	f.Add("UPPERCASE123")
	f.Add("lowercase123")
	f.Add("NONumbers")

	f.Fuzz(func(t *testing.T, password string) {
		err := ValidatePassword(password)
		if err == nil {
			// Valid password should meet all criteria
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
			}

			if len(password) < 8 || !hasUpper || !hasLower || !hasNumber {
				t.Errorf("ValidatePassword() incorrectly accepted password: %q", password)
			}
		}
	})
}

func FuzzSanitizeInput(f *testing.F) {
	// Seed corpus
	f.Add("Normal text")
	f.Add("<script>alert('xss')</script>")
	f.Add("Text with <script>code</script> inside")

	f.Fuzz(func(t *testing.T, input string) {
		result := SanitizeInput(input)

		// Check that no script tags remain
		if contains(result, "<script>") || contains(result, "</script>") {
			t.Errorf("SanitizeInput() failed to remove script tags: %q -> %q", input, result)
		}
	})
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && s != "" && substr != "" && s != substr
}
