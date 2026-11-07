package main

import (
	"context"
	"testing"

	"github.com/Shougo/goda-cmp.vim/cmp"
)

func TestConverterLspkind(t *testing.T) {
	f := converterLspkind{maxWidth: 5, ellipsis: "..."}
	in := []cmp.Item{
		{Word: "abcdefgh", Kind: "Function"},
		{Word: "ab", Kind: "Text"},
		{Word: "abcdefgh", Abbr: "abcdefgh", Kind: "Unknown"},
	}

	out, err := f.Filter(context.Background(), cmp.FilterInput{Items: in})
	if err != nil {
		t.Fatal(err)
	}
	if out[0].Kind != "󰊕" {
		t.Errorf("function kind = %q", out[0].Kind)
	}
	if out[0].Abbr != "ab..." {
		t.Errorf("truncated abbr = %q", out[0].Abbr)
	}
	if out[1].Kind != "󰉿" {
		t.Errorf("text kind = %q", out[1].Kind)
	}
	if out[1].Abbr != "" {
		t.Errorf("short abbr = %q", out[1].Abbr)
	}
	if out[2].Kind != "Unknown" {
		t.Errorf("unknown kind = %q", out[2].Kind)
	}
	if out[2].Abbr != "ab..." {
		t.Errorf("existing abbr = %q", out[2].Abbr)
	}
	if in[0].Kind != "Function" {
		t.Error("the input slice was modified")
	}
}
