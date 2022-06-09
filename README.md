# cmp-treesitter

nvim-cmp source for treesitter nodes. Using all treesitter highlight nodes as completion candicates.
LRU cache is used to improve performance.

# Setup

```lua
require'cmp'.setup {
  sources = {
    { name = 'treesitter' }
  }
}
```

# Screenshot

<img width="946" alt="treesitter_cmp" src="https://user-images.githubusercontent.com/1681295/138576812-95466e3f-80a6-4919-b3e9-2a8c79c67ccc.png">
<img width="586" alt="Screen Shot 2021-10-24 at 1 00 29 pm" src="https://user-images.githubusercontent.com/1681295/138577051-4de3dde5-8dea-49cc-88fb-b46372f0c5fa.png">
