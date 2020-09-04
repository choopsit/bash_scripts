# VIM TRICKS

## Toggle comments

Easy way to toggle comments without plugin

### Comment text

1. Go to beginning of first line of block to comment
2. Go visual mode: [Ctrl]+[V]
3. Go to last line of block: [number]+[J] (to go "number" lines down)
4. Go to insert mode: [Shift]+[I]
5. Add a comment symbol: "`#`" for bash or python
6. Press [Esc] to return to normal mode. This will comment the block

### Uncomment text

1. Go to the comment symbol ("`#`") of the first line of the block to uncomment
2. Go visual mode: [Ctrl]+[V]
3. Go to last line of block: [number]+[J] (to go "number" lines down)
4. Press [X] to delete comment symbols beginning each line of the block and go back to normal mode

## Test 'mdv.sh' validity

Multiple **code instance** in line: `code1`, `code2` and end of line

Liste1 with '`*`':
* line1
* line2

Liste2 with '`-`':
- line1
- line2

Liste ordonée:
1. line1
2. line2 with **bold** and __bold__ and _italic_ and *italic*

Multiple **code instance** in line: `code1` and `more code2` and "[__bold end__]" of "{_italic line_}"

_Italic line containing `code` in it (doesn't work yet)_

