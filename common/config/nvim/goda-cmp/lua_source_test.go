package main

import (
	"context"
	"testing"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda.vim/sdk"
)

type fakeHost struct {
	result   any
	callFn   string
	callArgs []any
}

func (f *fakeHost) Meta() sdk.Meta { return sdk.Meta{Host: sdk.HostNone} }

func (f *fakeHost) Call(_ context.Context, fn string, args ...any) (any, error) {
	f.callFn = fn
	f.callArgs = args
	return f.result, nil
}

func (f *fakeHost) Notify(context.Context, string, ...any) error { return nil }
func (f *fakeHost) Eval(context.Context, string) (any, error)    { return nil, nil }
func (f *fakeHost) Cmd(context.Context, string) error            { return nil }

func TestLuaSourceGather(t *testing.T) {
	host := &fakeHost{result: map[string]any{
		"start":      int64(3),
		"incomplete": true,
		"items": []any{
			map[string]any{
				"word":      "漢字",
				"abbr":      "漢字",
				"kind":      "Text",
				"sort_text": "00001",
				"data":      map[string]any{"midasi": "かんじ"},
			},
		},
	}}
	source := newLuaSource("skkelua", true)

	gathered, err := source.Gather(context.Background(), host, &cmp.Context{Input: "abc▽かんじ"})
	if err != nil {
		t.Fatal(err)
	}
	if gathered.Start != 3 {
		t.Errorf("start = %d, want 3", gathered.Start)
	}
	if !gathered.Incomplete {
		t.Error("incomplete = false, want true")
	}
	if len(gathered.Items) != 1 {
		t.Fatalf("got %d items, want 1", len(gathered.Items))
	}
	item := gathered.Items[0]
	if item.Word != "漢字" || item.Abbr != "漢字" || item.Kind != "Text" || item.SortText != "00001" {
		t.Errorf("item = %+v", item)
	}
	data, ok := item.UserData.(map[string]any)
	if !ok || data["midasi"] != "かんじ" {
		t.Errorf("user data = %#v", item.UserData)
	}
	if host.callFn != "luaeval" {
		t.Errorf("called %q, want luaeval", host.callFn)
	}
}

func TestLuaSourceDefaultPosition(t *testing.T) {
	host := &fakeHost{}
	source := newLuaSource("nvim_lsp", false)

	position := source.CompletePosition(context.Background(), host, &cmp.Context{Input: "hello.World"})
	if position != 6 {
		t.Errorf("position = %d, want 6", position)
	}
	if host.callFn != "" {
		t.Errorf("called %q, want no call", host.callFn)
	}
}

func TestLuaSourceCustomPosition(t *testing.T) {
	host := &fakeHost{result: int64(3)}
	source := newLuaSource("skkelua", true)

	position := source.CompletePosition(context.Background(), host, &cmp.Context{Input: "abc▽かんじ"})
	if position != 3 {
		t.Errorf("position = %d, want 3", position)
	}
	if host.callFn != "luaeval" {
		t.Errorf("called %q, want luaeval", host.callFn)
	}
}

func TestLuaSourceComplete(t *testing.T) {
	host := &fakeHost{}
	source := newLuaSource("skkelua", true)
	item := cmp.Item{
		Word:     "漢字",
		Source:   "skkelua",
		UserData: map[string]any{"midasi": "かんじ"},
	}

	err := source.OnCompleteDone(context.Background(), host, cmp.DoneArgs{
		Context: &cmp.Context{Input: "abc▽かんじ"},
		Item:    item,
	})
	if err != nil {
		t.Fatal(err)
	}
	if host.callFn != "luaeval" {
		t.Errorf("called %q, want luaeval", host.callFn)
	}
	if len(host.callArgs) < 2 {
		t.Fatalf("args = %#v", host.callArgs)
	}
	payload, ok := host.callArgs[1].(map[string]any)
	if !ok {
		t.Fatalf("payload = %#v", host.callArgs[1])
	}
	if payload["name"] != "skkelua" {
		t.Errorf("name = %v", payload["name"])
	}
	data, ok := payload["data"].(map[string]any)
	if !ok || data["midasi"] != "かんじ" {
		t.Errorf("data = %#v", payload["data"])
	}
}
