package main

import (
	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda-cmp.vim/ext/filter/converterremoveoverlap"
	"github.com/Shougo/goda-cmp.vim/ext/filter/convertertruncateabbr"
	"github.com/Shougo/goda-cmp.vim/ext/filter/matcherhead"
	"github.com/Shougo/goda-cmp.vim/ext/filter/sorterrank"
	"github.com/Shougo/goda-cmp.vim/ext/filter/sortertext"
	"github.com/Shougo/goda-cmp.vim/ext/source/buffer"
	"github.com/Shougo/goda-cmp.vim/ext/source/cmdline"
	"github.com/Shougo/goda-cmp.vim/ext/source/cmdlinehistory"
	"github.com/Shougo/goda-cmp.vim/ext/source/file"
	"github.com/Shougo/goda-cmp.vim/ext/ui/native"
	"github.com/Shougo/goda-cmp.vim/ext/ui/pum"
)

func newBuilder() *cmp.Builder {
	b := cmp.New()

	b.AddUI(pum.New())
	b.AddUI(native.New())

	b.AddSource(newLuaSource("skkelua", true))
	b.AddSource(newLuaSource("nvim_lsp", false))
	b.AddSource(newLuaSource("nvim_lua", false))
	b.AddSource(buffer.New(buffer.Params{}))
	b.AddSource(file.New(file.Params{}))
	b.AddSource(cmdline.New())
	b.AddSource(cmdlinehistory.New(cmdlinehistory.Params{}))

	b.AddFilter(matcherhead.New(matcherhead.Params{}))
	b.AddFilter(sorterrank.New())
	b.AddFilter(sortertext.New())
	b.AddFilter(converterremoveoverlap.New())
	b.AddFilter(convertertruncateabbr.New(convertertruncateabbr.Params{MaxWidth: 50}))
	b.AddFilter(skkeluaFirst{})

	configure(b)
	return b
}

func main() {
	newBuilder().Main()
}
