#!/bin/sh -e

usage() {
	echo "Usage: $(basename $0) [srctree]" >&2
	exit 1
}

svn_is_top()
{
	local relurl="$1"
	local nr

	nr=$(echo "$relurl" | \
	     sed -n 's/^\^\/trunk/trunk/;s/^\^\/branches\///;s/^\^\/tags\///;s/[/]\+/ /;p' | \
	     wc -w)
	if [ "$nr" != "1" ]; then
		return 1
	fi

	return 0
}

svn_list_files()
{
	local relurl="$1"

	if ! svn_is_top "$relurl"; then
		echo "$(basename $0): invalid top-level directory" >&2
		return 1
	fi

	$svn_cmd ls --recursive
}

svn_get_relurl()
{
	local info

	if ! info=$(env LANG= LC_ALL= LC_MESSAGES=C \
	                $svn_cmd --non-interactive info "$dir" 2>/dev/null); then
		return 1
	fi

	echo "$info" | sed --quiet 's;^Relative URL:[ \t]*;;p'
}

git_list_files()
{
	local top="$1"

	if [ "$top" != "$(pwd)" ]; then
		echo "$(basename $0): invalid top-level directory" >&2
		return 1
	fi

	$git_cmd ls-files
}

git_get_top()
{
	$git_cmd rev-parse --show-toplevel 2>/dev/null
}

git_cmd=${GIT:-git}
svn_cmd=${SVN:-svn}

srctree=.
if test $# -gt 0; then
	srctree=$1
	shift
fi
if test $# -gt 0 -o ! -d "$srctree"; then
	usage
fi

cd "$srctree"
if url=$(git_get_top); then
	git_list_files "$url"
elif url=$(svn_get_relurl); then
	svn_list_files "$url"
else
	echo "$(basename $0): unsupported version control system" >&2
	return 1
fi
