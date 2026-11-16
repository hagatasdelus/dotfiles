package main

import (
	"context"
	"testing"

	"github.com/Shougo/goda-cmp.vim/cmp"
)

func TestSkkeluaFirst(t *testing.T) {
	in := []cmp.Item{
		{Word: "buffer", Source: "buffer"},
		{Word: "first", Source: "skkelua"},
		{Word: "file", Source: "file"},
		{Word: "second", Source: "skkelua"},
	}

	out, err := (skkeluaFirst{}).Filter(context.Background(), cmp.FilterInput{Items: in})
	if err != nil {
		t.Fatal(err)
	}

	want := []string{"first", "second", "buffer", "file"}
	if len(out) != len(want) {
		t.Fatalf("got %d items, want %d", len(out), len(want))
	}
	for i, word := range want {
		if out[i].Word != word {
			t.Errorf("item %d = %q, want %q", i, out[i].Word, word)
		}
	}
}

func TestSkkeluaFirstWithoutSkkelua(t *testing.T) {
	in := []cmp.Item{
		{Word: "one", Source: "buffer"},
		{Word: "two", Source: "file"},
	}

	out, err := (skkeluaFirst{}).Filter(context.Background(), cmp.FilterInput{Items: in})
	if err != nil {
		t.Fatal(err)
	}
	for i := range in {
		if out[i].Word != in[i].Word {
			t.Errorf("item %d = %q, want %q", i, out[i].Word, in[i].Word)
		}
	}
}
