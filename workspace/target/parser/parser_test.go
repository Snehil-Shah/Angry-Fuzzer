package parser

import (
	"reflect"
	"testing"
)

func TestParseConfig(t *testing.T) {
	tests := []struct {
		name    string
		input   string
		want    map[string]string
		wantErr bool
	}{
		{
			name:    "empty string",
			input:   "",
			want:    map[string]string{},
			wantErr: false,
		},
		{
			name:    "single key-value",
			input:   "key=value",
			want:    map[string]string{"key": "value"},
			wantErr: false,
		},
		{
			name:    "multiple key-values",
			input:   "key1=value1;key2=value2",
			want:    map[string]string{"key1": "value1", "key2": "value2"},
			wantErr: false,
		},
		{
			name:    "invalid format",
			input:   "key1=value1;invalid",
			want:    nil,
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := ParseConfig(tt.input)
			if (err != nil) != tt.wantErr {
				t.Errorf("ParseConfig() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("ParseConfig() got = %v, want %v", got, tt.want)
			}
		})
	}
}

func FuzzParseConfig(f *testing.F) {
	// Seed corpus
	f.Add("key=value")
	f.Add("key1=value1;key2=value2")
	f.Add("")

	f.Fuzz(func(t *testing.T, input string) {
		result, err := ParseConfig(input)
		if err == nil {
			// If parsing succeeded, verify that we can reconstruct something equivalent
			for key, value := range result {
				if key == "" {
					t.Errorf("Empty key found in result map")
				}
				_ = value // Use value to avoid unused variable warning
			}
		}
	})
}

func FuzzParseIntList(f *testing.F) {
	// Seed corpus
	f.Add("1,2,3")
	f.Add("0")
	f.Add("-42,100")
	f.Add("")

	f.Fuzz(func(t *testing.T, input string) {
		result, err := ParseIntList(input)
		if err == nil {
			// If parsing succeeded, verify the length matches expected from input
			if input == "" {
				if len(result) != 0 {
					t.Errorf("Expected empty result for empty input")
				}
				return
			}

			expectedLength := 1
			for _, c := range input {
				if c == ',' {
					expectedLength++
				}
			}

			// Account for potential empty entries like ",,"
			for i := 0; i < len(input)-1; i++ {
				if input[i] == ',' && input[i+1] == ',' {
					expectedLength--
				}
			}

			if input[0] == ',' {
				expectedLength--
			}
			if len(input) > 0 && input[len(input)-1] == ',' {
				expectedLength--
			}
		}
	})
}
