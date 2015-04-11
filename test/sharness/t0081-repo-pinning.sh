#!/bin/sh
#
# Copyright (c) 2014 Jeromy Johnson
# MIT Licensed; see the LICENSE file in this repository.
#

test_description="Test ipfs repo pinning"

. lib/test-lib.sh

test_init_ipfs
test_launch_ipfs_daemon


HASH_FILE6="QmRsBC3Y2G6VRPYGAVpZczx1W7Xw54MtM1NcLKTkn6rx3U"
HASH_FILE5="QmaN3PtyP8DcVGHi3Q2Fcp7CfAFVcVXKddWbHoNvaA41zf"
HASH_FILE4="QmV1aiVgpDknKQugrK59uBUbMrPnsQM1F9FXbFcfgEvUvH"
HASH_FILE3="QmZrr4Pzqp3NnMzMfbMhNe7LghfoUFHVx7c9Po9GZrhKZ7"
HASH_FILE2="QmSkjTornLY72QhmK9NvAz26815pTaoAL42rF8Qi3w2WBP"
HASH_FILE1="QmbgX4aXhSSY88GHmPQ4roizD8wFwPX8jzTLjc8VAp89x4"
HASH_DIR3="QmRsCaNBMkweZ9vHT5PJRd2TT9rtNKEKyuognCEVxZxF1H"
HASH_DIR4="QmW98gV71Ns4bX7QbgWAqLiGF3SDC1JpveZSgBh4ExaSAd"
HASH_DIR2="QmTUTQAgeVfughDSFukMZLbfGvetDJY7Ef5cDXkKK4abKC"
HASH_DIR1="QmNyZVFbgvmzguS2jVMRb8PQMNcCMJrn9E3doDhBbcPNTY"

test_expect_success "'ipfs add dir' succeeds" '
	mkdir dir1 &&
	mkdir dir1/dir2 &&
	mkdir dir1/dir3 &&
	mkdir dir1/dir2/dir4 &&
	echo "some text 1" >dir1/file1 &&
	echo "some text 1" >dir1/dir2/file1 &&
	echo "some text 1" >dir1/dir2/dir4/file1 &&
	echo "some text 2" >dir1/file2 &&
	echo "some text 2" >dir1/dir3/file2 &&
	echo "some text 2" >dir1/dir2/dir4/file2 &&
	echo "some text 3" >dir1/file3 &&
	echo "some text 4" >dir1/dir2/file4 &&
	echo "some text 5" >dir1/dir3/file5 &&
	echo "some text 6" >dir1/dir2/dir4/file6 &&
	ipfs add -q -r dir1 | tail -n1 >actual1 &&
	echo "$HASH_DIR1" >expected1 &&
	test_cmp actual1 expected1
'

test_expect_success "objects are there" '
	ipfs cat "$HASH_FILE6" >FILE6_a &&
	ipfs cat "$HASH_FILE5" >FILE5_a &&
	ipfs cat "$HASH_FILE4" >FILE4_a &&
	ipfs cat "$HASH_FILE3" >FILE3_a &&
	ipfs cat "$HASH_FILE2" >FILE2_a &&
	ipfs cat "$HASH_FILE1" >FILE1_a &&
	ipfs ls "$HASH_DIR3"   >DIR3_a &&
	ipfs ls "$HASH_DIR4"   >DIR4_a &&
	ipfs ls "$HASH_DIR2"   >DIR2_a &&
	ipfs ls "$HASH_DIR1"   >DIR1_a
'

test_expect_success "added dir was pinned recursively" '
	ipfs pin ls -type=recursive >actual2 &&
	grep "$HASH_DIR1" actual2
'

test_expect_success "rest were pinned indirectly" '
	ipfs pin ls -type=indirect >actual3 &&
	grep "$HASH_FILE6" actual3 &&
	grep "$HASH_FILE5" actual3 &&
	grep "$HASH_FILE4" actual3 &&
	grep "$HASH_FILE3" actual3 &&
	grep "$HASH_FILE2" actual3 &&
	grep "$HASH_FILE1" actual3 &&
	grep "$HASH_DIR3" actual3 &&
	grep "$HASH_DIR4" actual3 &&
	grep "$HASH_DIR2" actual3
'

test_expect_success "added dir was NOT pinned indirectly" '
	test_must_fail grep "$HASH_DIR1" actual3
'

test_expect_success "nothing is pinned directly" '
	ipfs pin ls -type=direct >actual4 &&
	test_must_be_empty actual4
'

test_expect_success "'ipfs repo gc' succeeds" '
	ipfs repo gc >gc_out_actual &&
	test_must_be_empty gc_out_actual
'

test_expect_success "objects are still there" '
	ipfs cat "$HASH_FILE6" >FILE6_b && test_cmp FILE6_a FILE6_b &&
	ipfs cat "$HASH_FILE5" >FILE5_b && test_cmp FILE5_a FILE5_b &&
	ipfs cat "$HASH_FILE4" >FILE4_b && test_cmp FILE4_a FILE4_b &&
	ipfs cat "$HASH_FILE3" >FILE3_b && test_cmp FILE3_a FILE3_b &&
	ipfs cat "$HASH_FILE2" >FILE2_b && test_cmp FILE2_a FILE2_b &&
	ipfs cat "$HASH_FILE1" >FILE1_b && test_cmp FILE1_a FILE1_b &&
	ipfs ls "$HASH_DIR3"   >DIR3_b &&  test_cmp DIR3_a  DIR3_b &&
	ipfs ls "$HASH_DIR4"   >DIR4_b &&  test_cmp DIR4_a  DIR4_b &&
	ipfs ls "$HASH_DIR2"   >DIR2_b &&  test_cmp DIR2_a  DIR2_b &&
	ipfs ls "$HASH_DIR1"   >DIR1_b &&  test_cmp DIR1_a  DIR1_b
'

test_expect_success "remove dir recursive pin succeeds" '
	echo "unpinned $HASH_DIR1" >expected5 &&
	ipfs pin rm -r "$HASH_DIR1" >actual5 &&
	test_cmp expected5 actual5
'

test_expect_success "none are pinned any more" '
	ipfs pin ls -type=recursive >actual6 &&
	ipfs pin ls -type=indirect >>actual6 &&
	ipfs pin ls -type=direct >>actual6 &&
	ipfs pin ls -type=all >>actual6 &&
	test_must_fail grep "$HASH_FILE6" actual6 &&
	test_must_fail grep "$HASH_FILE5" actual6 &&
	test_must_fail grep "$HASH_FILE4" actual6 &&
	test_must_fail grep "$HASH_FILE3" actual6 &&
	test_must_fail grep "$HASH_FILE2" actual6 &&
	test_must_fail grep "$HASH_FILE1" actual6 &&
	test_must_fail grep "$HASH_DIR3"  actual6 &&
	test_must_fail grep "$HASH_DIR4"  actual6 &&
	test_must_fail grep "$HASH_DIR2"  actual6 &&
	test_must_fail grep "$HASH_DIR1"  actual6
'

test_expect_success "pin some directly and indirectly" '
	ipfs pin add    "$HASH_DIR1"  >actual7 &&
	ipfs pin add -r "$HASH_DIR2"  >>actual7 &&
	ipfs pin add    "$HASH_FILE1" >>actual7 &&
	echo "pinned $HASH_DIR1 directly"	   >expected7 &&
	echo "pinned $HASH_DIR2 recursively" >>expected7 &&
	echo "pinned $HASH_FILE1 directly"	 >>expected7 &&
	test_cmp expected7 actual7
'

test_expect_success "pin lists look good" '
	ipfs pin ls -type=recursive >ls_recursive &&
	ipfs pin ls -type=indirect >ls_indirect &&
	ipfs pin ls -type=direct >ls_direct &&
	test_must_fail grep "$HASH_DIR1" ls_indirect &&
	               grep "$HASH_DIR1" ls_direct   &&
	test_must_fail grep "$HASH_DIR1" ls_recursive &&
	test_must_fail grep "$HASH_DIR2" ls_indirect &&
	test_must_fail grep "$HASH_DIR2" ls_direct   &&
                 grep "$HASH_DIR2" ls_recursive &&
	test_must_fail grep "$HASH_DIR3" ls_indirect &&
	test_must_fail grep "$HASH_DIR3" ls_direct   &&
  test_must_fail grep "$HASH_DIR3" ls_recursive &&
	               grep "$HASH_DIR4" ls_indirect &&
	test_must_fail grep "$HASH_DIR4" ls_direct   &&
  test_must_fail grep "$HASH_DIR4" ls_recursive &&
	               grep "$HASH_FILE1" ls_indirect &&
	               grep "$HASH_FILE1" ls_direct   &&
	test_must_fail grep "$HASH_FILE1" ls_recursive &&
	               grep "$HASH_FILE2" ls_indirect &&
	test_must_fail grep "$HASH_FILE2" ls_direct   &&
	test_must_fail grep "$HASH_FILE2" ls_recursive &&
	test_must_fail grep "$HASH_FILE3" ls_indirect &&
	test_must_fail grep "$HASH_FILE3" ls_direct   &&
	test_must_fail grep "$HASH_FILE3" ls_recursive &&
		             grep "$HASH_FILE4" ls_indirect &&
	test_must_fail grep "$HASH_FILE4" ls_direct   &&
	test_must_fail grep "$HASH_FILE4" ls_recursive &&
	test_must_fail grep "$HASH_FILE5" ls_indirect &&
	test_must_fail grep "$HASH_FILE5" ls_direct   &&
	test_must_fail grep "$HASH_FILE5" ls_recursive &&
	test_must_fail grep "$HASH_FILE6" ls_indirect &&
	               grep "$HASH_FILE6" ls_direct   &&
	               grep "$HASH_FILE6" ls_recursive
'

test_expect_success "'ipfs repo gc' succeeds" '
	ipfs repo gc >gc_out_actual2 &&
	grep "removed $HASH_FILE3" gc_out_actual2 &&
	grep "removed $HASH_FILE5" gc_out_actual2 &&
	grep "removed $HASH_DIR3" gc_out_actual2
'

test_expect_success "some objects are still there" '
	ipfs cat "$HASH_FILE6" >FILE6_b && test_cmp FILE6_a FILE6_b &&
	ipfs cat "$HASH_FILE4" >FILE4_b && test_cmp FILE4_a FILE4_b &&
	ipfs cat "$HASH_FILE2" >FILE2_b && test_cmp FILE2_a FILE2_b &&
	ipfs cat "$HASH_FILE1" >FILE1_b && test_cmp FILE1_a FILE1_b &&
	ipfs ls "$HASH_DIR4"   >DIR4_b &&  test_cmp DIR4_a  DIR4_b &&
	ipfs ls "$HASH_DIR2"   >DIR2_b &&  test_cmp DIR2_a  DIR2_b &&
	ipfs ls "$HASH_DIR1"   >DIR1_b &&  test_cmp DIR1_a  DIR1_b &&
	test_must_fail ipfs cat "$HASH_FILE5" &&
	test_must_fail ipfs cat "$HASH_FILE3" &&
	test_must_fail ipfs ls "$HASH_DIR3"
'

test_expect_success "recursive pin fails without objects" '
	ipfs pin rm "$HASH_DIR1" &&
	test_must_fail ipfs pin add -r "$HASH_DIR1" 2>err_expected8 &&
	grep "context exceeded" err_expected8
'

test_kill_ipfs_daemon

test_done
