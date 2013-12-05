check:
	cd tools/test; make api_selftest | grep -C 100000 tests_passed_pct | grep -C 100000 100
