// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module util

fn test_in() {
	assert @in(0, 0, 1)
	assert @in(1, 0, 1)
	assert !@in(2, 0, 1)

	assert @in('c', 'a', 'z')

	assert in2('c', '0', '2', 'a', 'c')
	assert in2('1', '0', '2', 'a', 'c')
	assert !in2('9', '0', '2', 'a', 'c')
	assert !in2('z', '0', '2', 'a', 'c')
}

struct Ref {
mut:
	ref &string = unsafe { 0 }
}

fn (v Ref) opt() ?&string {
	return nil_to_none(v.ref)
}

fn test_nil_to_none() {
	mut v := Ref{}
	if _ := v.opt() {
		assert false
	}
	s := 'x'
	v.ref = &s
	assert v.opt() or { assert false } == &s
}

struct Foo {}

struct Bar {}

fn (b Bar) str() string {
	return '{}'
}

type FooBar = Bar | Foo

fn test_struct_name() {
	assert struct_name(Foo{}) == 'Foo'
	assert struct_name(Bar{}) == 'Bar'
	assert struct_name(FooBar(Foo{})) == 'Foo'
}

fn test_to_octal() {
	assert to_octal(1) == '1'
	assert to_octal(8) == '10'
	assert to_octal('0x10'.int()) == '20'
}
