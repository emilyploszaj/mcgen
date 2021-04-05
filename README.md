# MCGen
`mcgen` is a CLI utility to generate json files for Minecraft blocks and items. It has the ability to generate basic needed jsons for item and blocks, including item models, block state definitions, block models, block item models, and block loot tables. It also has support for user provided templates, located at `~/.mcgen/templates/`.

### Examples
`mcgen block diamond_tiles diamond_bricks`
Generates block state definitions, block models, block item models, and block loot tables for `<namespace>:diamond_tiles` and `<namespace>:diamond_bricks`. If the working directory is a fabric modding environment, this namespace will be taken from `fabric.mod.json` by default, and can be overriden with `mcgen block --namespace=<namespace> diamond_tiles diamond_bricks`

`mcgen item golden_chain`
Generates an item model for `<namespace>:golden_chain`

`mcgen template [--verbose]`
Displays available templates (optionally with a more verbose display)

`mcgen block --namespace=changed --template=cross --template=flat green_flower`
Generates block state definitions, block models, block item models, and block loot tables for `changed:green_flower` using the user provided templates `cross` and `flat`, replacing default json templates with those provided.