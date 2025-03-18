package parser

import (
	"errors"
	"strconv"
	"strings"
)

// ParseConfig parses a simple config format: key=value;key2=value2
func ParseConfig(input string) (map[string]string, error) {
	result := make(map[string]string)

	if input == "" {
		return result, nil
	}

	parts := strings.Split(input, ";")
	for _, part := range parts {
		keyValue := strings.Split(part, "=")
		if len(keyValue) != 2 {
			return nil, errors.New("invalid format: expected key=value")
		}

		key := strings.TrimSpace(keyValue[0])
		value := strings.TrimSpace(keyValue[1])

		// BUG: doesn't check for duplicate keys (will be found by fuzzing)
		result[key] = value
	}

	return result, nil
}

// ParseIntList parses a comma-separated list of integers
func ParseIntList(input string) ([]int, error) {
	if input == "" {
		return []int{}, nil
	}

	parts := strings.Split(input, ",")
	result := make([]int, 0, len(parts))

	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		// BUG: No handling for integer overflow (will be found by fuzzing)
		num, err := strconv.Atoi(trimmed)
		if err != nil {
			return nil, err
		}
		result = append(result, num)
	}

	return result, nil
}
