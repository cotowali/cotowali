// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

module ast

struct FailVisitor {}

fn (v FailVisitor) visit(node Node) ? {
	return error('err')
}

struct EmptyVisitor {}

fn (v EmptyVisitor) visit(node Node) ? {
}

fn do_visit(visitor Visitor, node Node) ? {
	return visitor.visit(node)
}

fn test_visit() {
	if _ := do_visit(EmptyVisitor{}, Stmt(EmptyStmt{})) {
		assert true
	} else {
		assert false
	}

	if _ := do_visit(FailVisitor{}, Stmt(EmptyStmt{})) {
		assert false
	} else {
		assert true
	}
}
