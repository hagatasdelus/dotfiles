package main

import "testing"

func TestNewBuilderValidates(t *testing.T) {
	if err := newBuilder().Validate(); err != nil {
		t.Fatal(err)
	}
}
