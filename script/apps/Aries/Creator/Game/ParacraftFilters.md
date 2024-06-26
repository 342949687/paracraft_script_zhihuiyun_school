# Paracraft Filters
Filters are integration points in Paracraft, which allows paracraft mod/app developers to customize the application cooperatively. 
Filters is a design pattern of input-output chains. Please see [script/ide/System/Core/Filters.lua](https://github.com/NPLPackages/main/blob/master/script/ide/System/Core/Filters.lua) for details.

> One can search for `GameLogic.GetFilters():apply_filters`, such as below:

```lua
xmlRoot = GameLogic.GetFilters():apply_filters("block_types", xmlRoot);
```

## How to Use Filters In Paracraft
There is a global function called `GameLogic.GetFilters()` which returns the primary filter in Paracraft. 
One should `add_filter` before `apply_filter`, so one should call `add_filter` code as early as possible to install all filters used by your plugin, such as when Mod is initialized or application just started. 

The following example code, registered a new item.
```lua
-- register a new block item, id < 512 is internal blocks, which is not recommended to modify. 
GameLogic.GetFilters():add_filter("block_types", function(xmlRoot) 
	local blocks = commonlib.XPath.selectNode(xmlRoot, "/blocks/");
	if(blocks) then
		blocks[#blocks+1] = {name="block", attr={
			id = 512, threeSideTex = "true",
			text = "Demo Item", name = "DemoItem",
			texture="Texture/blocks/bookshelf_three.png",
			obstruction="true", solid="true", cubeMode="true",
		}}
		LOG.std(nil, "info", "DemoItem", "a new block is registered");
	end
	return xmlRoot;
end)
```

## List of Paracraft Filters
This gives an overview of filters in paracraft. Please search the source code of paracraft for how to use these filters. 

- block related:
  - "block_type", xmlRoot: for registering new item type
  - "block_list", xmlRoot: for registering new item type in builder GUI
  - "block_types_template", xmlRoot: for registering or modify block type's template
  - "register_item": for registering new item type in client
  - "CodeAPIInstallMethods", codeBlockApiCollections: inject custom code block apis.
  - "ParacraftCodeBlocklyAppendDefinitions",ParacraftCodeBlockly: inject custom code blocks. 
  - "ParacraftCodeBlocklyCategories", ParacraftCodeBlocklyDefaultCategories: inject custom code block categories. 

- user input mouse and keyboard:
  - "DefaultContext", context, mode: getting the default scene context for user input
  - "TouchVirtualKeyboardIcon", keyboardIcon: custom mobile keyboard icon.
  - "TouchMiniKeyboard", TouchMiniKeyboard: custom touchMiniKeyboard.
  - "KeyPressEvent" , event:KeyEvent KeyPressEvent: custom KeyPressEvent
- GUI:
  - "File.MCMLWindowFrame", params: all mcml v1 pages goes through this filter. 
  - "File.MCMLWindowFrameClose": called when the v1 pages is closed
  - "cellar.main_login.show_login_mode_page": this is the first user interface shown. One must install this filter very early, such as in mod.loadOnStartup. 
  - "ShowClientUpdaterNotice": show client updater notice when stared updater.
  - "HideClientUpdaterNotice": hide client updater notice when finished updater.
  - "InitDesktop", bSkipDefaultDesktop: called to init the default desktop UI
  - "ActivateDesktop", bIgnoreDefaultDesktop, mode: called when desktop mode is changing. This is the place to initialize your custom GUI. 
  - "DesktopModeChanged", mode: called when desktop mode is already changed. This is the place to initialize your custom GUI after default GUI is shown. 
  - "show", name, bIsShow: hook `/show name` command to display a custom gui via command
  - "cmd_open_url", url, options: hook `/open url` command to display a custom url via command
  - "InternetLoadWorld.ShowPage", bEnable, bShow: whether to show the default load world window. We can use this filter to replace the default load world window.
  - "SaveWorldPage.ShowSharePage", bEnable: We can use this filter to replace the default share world window.
  - "OnBeforeShowExitDialog", true: return false to cancel
  - "ShowExitDialog", {text, callback}: use this filter to display a dialog when user exits the application, return nil if one wants to replace the implementation.
  - "show_custom_create_new_world", behavior("show" or "close"):use this filter to customize your CreateNewWorld page.
  - "show_custom_download_world", behavior("show" or "close"), url:use this filter to customize your DownloadWorld page.
  - "OnShowEscFrame", bShow: whenever the esc key frame window is shown or hide
  - "AriesWindow.CustomStyle": false, rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css, mode: custom aries window styles.  
  - "ShowLoginBackgroundPage", true: custom login background page when.
  - "ChestPage.PageParams", chestPageDefaultParams: custom chest page.
  - "EnterTextDialog.PageParams", enterTextDialogPageParams, params: custom enter text dialog page params.
  - "EscFramePage.ShowPage", false: Used to customize the dialog box that pops up when exiting the world.
  - "InventoryPage.PageParams", inventoryPageDefaultParams: custom backpack interface.
  - "SkinPage.PageParams", skinPageDefaultParams: custom skin page. 
  - "SystemSettingsPage.CheckBoxBackground", pageInfo, page, name, bChecked: custom system setting dialog's checkbox checked styles.
  - "SystemSettingsPage.PageParams", defaultPageParams: custom system setting page.
  - "MainUIButtons": custom main page ui.
  - "DesktopMenuPage.ShowPage": bShow:boolean    custom DesktopMenuPage.ShowPage
  - "QuickSelectBar.ShowPage":bShow:boolean custom QuickSelectBar.ShowPage
  - "show_certificate_page": Show certificate page
  - "check_signed_in": Show login modal if not login
  - "show_login_page": Show login page
  - "show_create_page": Show create page
  - "show_console_page": Show console page
  - "show_offical_worlds_page": Show offical worlds page
  - "show_server_page": Show server page
  - "cellar.my_school.after_selected_school": Show my school page and return is selected a school.
  - "cellar.vip_notice.init": Show vip notice page
  - "cellar.vip_notice.close": Close vip notice page
  - "user_skin_change": User skin changes
  - "WebviewShowWindow", state, windowId: when a webview window of given id is first shown. Consider using "ShowTopWindow" filter instead, see below. 
  - "ShowTopWindow", state, windowName, windowType: when a top window of given name is first shown. windowName can be "Desktop.OnExit"|"panorama_preview"|"RedSummerCampPPtPage" and more. it also include all WebviewShowWindow window names. windowType can be nil or "webview"

- world:
  - "OnWorldInitialRegionsLoaded": called only once after the first world regions are loaded. 
  - "PlayerHasLoginPosition", nil, x,y,z: called whenever the player is at its spawn position in both local or remote world.
  - "BeforeSetSpawnPoint", {x,y,z}: before player spawn point is set
  - "SetSpawnPoint", nil, x,y,z: whenever the player spawn point is set. 
  - "before_generate_chunk", x, z:
  - "after_generate_chunk", x, z:
  - "load_world_info", worldInfo, node：
  - "save_world_info", worldInfo, node:
  - "OnBeforeLoadBlockRegion", true, x, y:
  - "OnSaveBlockRegion", true, region_x, region_z, "region.xml":
  - "OnLoadBlockRegion", true, x, y:
  - "OnUnLoadBlockRegion", true, x, y:
  - "worldFileChanged", msg:
  - "GetWorldGeneratorClass", generator, name: get world generator by name filter. Use this to add custom world generators
  - "OnClickCreateWorld"
  - "OnBeforeLoadWorld"
  - "OnWorldLoaded" when world is successfully loaded
  - "OnWillUnloadWorld" before world unloaded
  - "OnWorldUnloaded" when world is unloaded
  - "shouldRefreshWorldFile" true, fullname: whether to refresh the world file. 
  - "cmd_loadworld", url, options: hook `/loadworld url` command
  - "LocalLoadWorld.GetWorldFolderFullPath" filepath:
  - "download_remote_world_show_bbs", true: whether show bbs when downloading remote world.
  - "file_downloader_show_label", true, when fileDownloader downloads, choose whether to display the download progress prompt.
  - "WorldName.ResetWindowTitle": get custom window title for the world
  - "OnEnterParaWorldGrid" params {projectName, userId, x, y}: when player enters a new paraworld grid at x, y
  - "compare_init": Compare current world bewteen remove version and local version
  - "current_world": Get current selected world
  - "check_and_updated_before_enter_my_home": Check and updated brefore enter my home
  - "service.local_service_world.set_community_world": set community world enabled.
  - "service.local_service_word.is_community_world": is community world.
  - "OnCreateHomeWorld": create home world event.
  - "OnPlayMovieText": play movie text event.
  - "OnMacroMovieText": play macro text event.
  - "OnWorldTageChange": on world tage change
  - "SyncWorldFinish": on world sync finish
  - "SyncWorldFinishBegin": on world sync start
  - "SyncWorldFinishNoUI": on world sync finish
  - "SyncWorldEnded": on syncfinish page closed
  - "EnterWorldFailed": onEnterWorldFailed
  --"ConnectServer": ConnectServer failed or success
  --"CheckShowIfApplyStagedChanges", true: if we shall display an UI asking the user if we need to recover

- global:
  - "register_classes_into_sandbox_api", additionalEnv:
  - "desktop_menu", menu_items:
  - "new_item", itemStackArray, self:
  - "item_client_new_item_type_added", block_id, item:
  - "user_event_stat", category, action, value, label:
  - "user_behavior", event tracking
  - "on_permission_load",when load user permission complete 
  - "OnBeforeRestart", appName: before entire NPL runtime is restarted. 
  - "GameName", titlename: get game name string
  - "GameDescription", desc: get game description string, which will be shown in the window title area
  - "HandleGlobalKeyByRETURN", custom handle global key by DIK_RETURN
  - "HandleGlobalKeyBySLASH", custom handle global key by DIK_SLASH
  - "CheckInstallUrlProtocol" false, determine whether checking install paracraft url protocol
  - "AppInstallDetails" AppInstallDetails, custom app_install_details 
  - "is_signed_in": Is user signed in
  - "login_with_token": Login with token
  - "logout": Logout
  - "get_user_type": Get user type
  - "get_user_id": Get user Id
  - "set_mode": Set game mode(game/edit)
  - "open_keepwork_url": Open Keepwork url with token
  - "get_keepwork_url": Get base keepwork url
  - "get_world_by_project_id": Get current world instance by project id
  - "get_project_id_by_lesson_id": Get project id by lesson id
  - "get_my_orgs_and_schools": Get my orgs and schools
  - "get_school_region": Get school region province/city/area
  - "get_single_file": Get single file
  - "get_single_file_by_commit_id": Get single file by commit id
  - "get_socket_url": Get socket url
  - "get_core_api_url": Get core api url
  - "OnCloseAppWindow": PapaAdventure Exit App
- file exporters:
  - "file_exported", id, filename:
  - "GetExporters", exporters: file exporters
  - "export_to_file", filename:
  - "select_exporter", id:
  - "OnInstallModel": filename, url: called when /install -ext bmax commands are executed. 
  - "CheckInstallUrlProtocol" false, determine whether checking install paracraft url protocol

- command:
  - "register_command": Commands, slashCommandObj:  register additional commands

- networking:
  - "handleLogin", packet_login: whenever client received confirmed login packet from server. 
  - "entity_player_mp_other_entity_action_state_updated", entity_player_mp_other: after every time entity action state get updated for EntityPlayerMPOther
  - "entity_player_mp_entity_action_state_updated", entity_player_mp: after every time entity action state get updated for EntityPlayerMP
  - "net_status", socket close or open status
- movie: 
  - "pop_movie_mode", lastMode:when the movie mode is popped
- sound: 
  - "sound_starts_playing", when the sound starts playing
- downloadFile: 
  - "downloadFile_notify", downloadState(0:downloading, 1:complete, 2:terminated),text(downloadFile text tips),currentFileSize, totalFileSize
- urlprotocol:  
  - "load_world_from_cmd_precheck",  hijacking cmdline_world, return a custom path
- tasks:
  - "OnlineStore.CustomOnlineStoreUrl", OnlineStoreUrl, name: add custom online store url based on name
  - "OnlineStore.getPageParamUrl", url: default url in online store params, name: custom url paramater
- online:
  - "Player.LoadRemoteData": nil, name, default_value: 
  - "Player.SaveRemoteData": nil, name, value, bDeferSave: 
- code block editor
  - "CodeBlockUIUrl": defaultCodeBlockEditorUrl:custom code block default html path
  - "CodeBlockEditorOpened": nil, custom code block editor
  - "CustomCodeBlockClicked": false, determine whether code block can be opened
  - "OnCodeBlockLineStep": locationInfo: in format of "filename:line:"
- player rules
  - "OnPlayerRuleChange": when player rule register or unregister
  - "OnPlayerToggleFly": when player toggle flying

## Adding New filters
If you want to add new filters to paracraft, you can either start a new issue on github or send us a pull request with your code. 
