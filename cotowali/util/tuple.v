module util

pub struct Tuple2<T, U> {
pub mut:
	v1 T
	v2 U
}

pub fn tuple2<T, U>(v1 T, v2 U) Tuple2<T, U> {
	return Tuple2<T,U>{v1, v2}
}

pub fn pair<T, U>(v1 T, v2 U) Tuple2<V, U> {
	return tuple2(v1, v2)
}

pub fn (t Tuple2<T, U>) str() string {
	return '($t.v1.str(), $t.v2.str())'
}

/*
TODO: wait to fix v bug

struct Tuple3<T, U, V> {
pub mut:
	v1 T
	v2 U
	v3 V
}

pub fn tuple3<T, U, V>(v1 T, v2 U, v3 V) Tuple3<T, U, V> {
	return Tuple3<T,U,V>{v1, v2, v3}
}

pub fn (t Tuple3<T, U, V>) str() string {
	return '($t.v1.str(), $t.v2.str(), $t.v3.str())'
}

struct Tuple4<T, U, V, W> {
pub mut:
	v1 T
	v2 U
	v3 V
	v4 W
}

pub fn tuple4<T, U, V, W>(v1 T, v2 U, v3 V, v4 W) Tuple4<T, U, V, W> {
	return Tuple4<T,U,V,W>{v1, v2, v3, v4}
}

pub fn (t Tuple4<T, U, V, W>) str() string {
	return '($t.v1.str(), $t.v2.str(), $t.v3.str(), $t.v4.str())'
}
*/
