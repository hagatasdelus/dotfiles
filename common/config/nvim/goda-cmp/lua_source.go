package main

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda.vim/sdk"
)

type luaItem struct {
	Word       string `json:"word"`
	Abbr       string `json:"abbr"`
	Menu       string `json:"menu"`
	Kind       string `json:"kind"`
	Info       string `json:"info"`
	Dup        int    `json:"dup"`
	FilterText string `json:"filter_text"`
	SortText   string `json:"sort_text"`
	Data       any    `json:"data"`
}

type luaGathered struct {
	Start      int       `json:"start"`
	Items      []luaItem `json:"items"`
	Incomplete bool      `json:"incomplete"`
}

type luaSource struct {
	name           string
	customPosition bool
}

func newLuaSource(name string, customPosition bool) luaSource {
	return luaSource{name: name, customPosition: customPosition}
}

func (s luaSource) Name() string { return s.name }

func (s luaSource) call(ctx context.Context, h sdk.Host, method string, payload map[string]any) (any, error) {
	payload["name"] = s.name
	return h.Call(ctx, "luaeval", fmt.Sprintf(`require("plugins.goda.sources").%s(_A)`, method), payload)
}

func (s luaSource) Gather(ctx context.Context, h sdk.Host, c *cmp.Context) (cmp.Gathered, error) {
	v, err := s.call(ctx, h, "gather", map[string]any{"context": c})
	if err != nil {
		return cmp.Gathered{}, err
	}

	var gathered luaGathered
	if err := sdk.Decode(v, &gathered); err != nil {
		return cmp.Gathered{}, err
	}

	items := make([]cmp.Item, 0, len(gathered.Items))
	for _, item := range gathered.Items {
		items = append(items, cmp.Item{
			Word:       item.Word,
			Abbr:       item.Abbr,
			Menu:       item.Menu,
			Kind:       item.Kind,
			Info:       item.Info,
			Dup:        item.Dup,
			FilterText: item.FilterText,
			SortText:   item.SortText,
			UserData:   item.Data,
		})
	}
	return cmp.Gathered{Start: gathered.Start, Items: items, Incomplete: gathered.Incomplete}, nil
}

func (s luaSource) CompletePosition(ctx context.Context, h sdk.Host, c *cmp.Context) int {
	if !s.customPosition {
		return c.KeywordStart()
	}
	v, err := s.call(ctx, h, "position", map[string]any{"context": c})
	if err != nil {
		return -1
	}
	position, ok := toInt(v)
	if !ok {
		return -1
	}
	return position
}

func (s luaSource) OnCompleteDone(ctx context.Context, h sdk.Host, a cmp.DoneArgs) error {
	_, err := s.call(ctx, h, "complete", map[string]any{
		"context": a.Context,
		"data":    a.Item.UserData,
	})
	return err
}

func (s luaSource) Resolve(ctx context.Context, h sdk.Host, a cmp.DoneArgs) (cmp.Item, error) {
	v, err := s.call(ctx, h, "resolve", map[string]any{
		"context": a.Context,
		"data":    a.Item.UserData,
	})
	if err != nil || v == nil {
		return a.Item, err
	}

	var resolved luaItem
	if err := sdk.Decode(v, &resolved); err != nil {
		return a.Item, err
	}

	item := a.Item
	if resolved.Word != "" {
		item.Word = resolved.Word
	}
	if resolved.Abbr != "" {
		item.Abbr = resolved.Abbr
	}
	if resolved.Menu != "" {
		item.Menu = resolved.Menu
	}
	if resolved.Kind != "" {
		item.Kind = resolved.Kind
	}
	if resolved.Info != "" {
		item.Info = resolved.Info
	}
	if resolved.FilterText != "" {
		item.FilterText = resolved.FilterText
	}
	if resolved.SortText != "" {
		item.SortText = resolved.SortText
	}
	if resolved.Data != nil {
		item.UserData = resolved.Data
	}
	return item, nil
}

func toInt(v any) (int, bool) {
	switch n := v.(type) {
	case int:
		return n, true
	case int64:
		return int(n), true
	case float64:
		return int(n), true
	case json.Number:
		i, err := n.Int64()
		return int(i), err == nil
	}
	return 0, false
}
