package main

import (
	"context"

	"github.com/Shougo/goda-cmp.vim/cmp"
)

type skkeluaFirst struct{}

func (skkeluaFirst) Name() string { return "skkeluafirst" }

func (skkeluaFirst) Filter(_ context.Context, in cmp.FilterInput) ([]cmp.Item, error) {
	first := make([]cmp.Item, 0, len(in.Items))
	rest := make([]cmp.Item, 0, len(in.Items))
	for _, item := range in.Items {
		if item.Source == "skkelua" {
			first = append(first, item)
			continue
		}
		rest = append(rest, item)
	}
	return append(first, rest...), nil
}
