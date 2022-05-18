tool
extends PopupPanel


signal key_selected

const valid_locales = ["aa","aa_DJ","aa_ER","aa_ET","af","af_ZA","agr_PE","ak_GH","am_ET","an_ES","anp_IN","ar","ar_AE","ar_BH","ar_DZ","ar_EG","ar_IQ","ar_JO","ar_KW","ar_LB","ar_LY","ar_MA","ar_OM","ar_QA","ar_SA","ar_SD","ar_SS","ar_SY","ar_TN","ar_YE","as_IN","ast_ES","ayc_PE","ay_PE","az_AZ","be","be_BY","bem_ZM","ber_DZ","ber_MA","bg","bg_BG","bhb_IN","bho_IN","bi_TV","bn","bn_BD","bn_IN","bo","bo_CN","bo_IN","br_FR","brx_IN","bs_BA","byn_ER","ca","ca_AD","ca_ES","ca_FR","ca_IT","ce_RU","chr_US","cmn_TW","crh_UA","csb_PL","cs","cs_CZ","cv_RU","cy_GB","da","da_DK","de","de_AT","de_BE","de_CH","de_DE","de_IT","de_LU","doi_IN","dv_MV","dz_BT","el","el_CY","el_GR","en","en_AG","en_AU","en_BW","en_CA","en_DK","en_GB","en_HK","en_IE","en_IL","en_IN","en_NG","en_NZ","en_PH","en_SG","en_US","en_ZA","en_ZM","en_ZW","eo","es","es_AR","es_BO","es_CL","es_CO","es_CR","es_CU","es_DO","es_EC","es_ES","es_GT","es_HN","es_MX","es_NI","es_PA","es_PE","es_PR","es_PY","es_SV","es_US","es_UY","es_VE","et","et_EE","eu","eu_ES","fa","fa_IR","ff_SN","fi","fi_FI","fil","fil_PH","fo_FO","fr","fr_BE","fr_CA","fr_CH","fr_FR","fr_LU","fur_IT","fy_DE","fy_NL","ga","ga_IE","gd_GB","gez_ER","gez_ET","gl_ES","gu_IN","gv_GB","hak_TW","ha_NG","he","he_IL","hi","hi_IN","hne_IN","hr","hr_HR","hsb_DE","ht_HT","hu","hu_HU","hus_MX","hy_AM","ia_FR","id","id_ID","ig_NG","ik_CA","is","is_IS","it","it_CH","it_IT","iu_CA","ja","ja_JP","kab_DZ","ka","ka_GE","kk_KZ","kl_GL","km_KH","kn_IN","kok_IN","ko","ko_KR","ks_IN","ku","ku_TR","kw_GB","ky_KG","lb_LU","lg_UG","li_BE","li_NL","lij_IT","ln_CD","lo_LA","lt","lt_LT","lv","lv_LV","lzh_TW","mag_IN","mai_IN","mg_MG","mh_MH","mhr_RU","mi","mi_NZ","miq_NI","mk","mk_MK","ml","ml_IN","mni_IN","mn_MN","mr_IN","ms","ms_MY","mt","mt_MT","my_MM","myv_RU","nah_MX","nan_TW","nb","nb_NO","nds_DE","nds_NL","ne_NP","nhn_MX","niu_NU","niu_NZ","nl","nl_AW","nl_BE","nl_NL","nn","nn_NO","nr_ZA","nso_ZA","oc_FR","om","om_ET","om_KE","or_IN","os_RU","pa_IN","pa_PK","pap","pap_AN","pap_AW","pap_CW","pl","pl_PL","pr","ps_AF","pt","pt_BR","pt_PT","quy_PE","quz_PE","raj_IN","ro","ro_RO","ru","ru_RU","ru_UA","rw_RW","sa_IN","sat_IN","sc_IT","sco","sd_IN","se_NO","sgs_LT","shs_CA","sid_ET","si","si_LK","sk","sk_SK","sl","sl_SI","so","so_DJ","so_ET","so_KE","so_SO","son_ML","sq","sq_AL","sq_KV","sq_MK","sr","sr_Cyrl","sr_Latn","sr_ME","sr_RS","ss_ZA","st_ZA","sv","sv_FI","sv_SE","sw_KE","sw_TZ","szl_PL","ta","ta_IN","ta_LK","tcy_IN","te","te_IN","tg_TJ","the_NP","th","th_TH","ti","ti_ER","ti_ET","tig_ER","tk_TM","tl_PH","tn_ZA","tr","tr_CY","tr_TR","ts_ZA","tt_RU","ug_CN","uk","uk_UA","unm_US","ur","ur_IN","ur_PK","uz","uz_UZ","ve_ZA","vi","vi_VN","wa_BE","wae_CH","wal_ET","wo_SN","xh_ZA","yi_US","yo_NG","yue_HK","zh","zh_CN","zh_HK","zh_SG","zh_TW","zu_ZA"]


func show_keys():
	_clear_buttons()
	
	var translation_location = DialogicResources.get_settings_value("Dialog", "TranslationLocation", "")
	var translation_files = _get_translation_files(translation_location)
	for file in translation_files:
		var new_button = Button.new()
		$HBoxContainer/ScrollContainer/Content.add_child(new_button)
		new_button.text = file.split(".")[0]
		new_button.text = new_button.text.split("/")[-1]
		new_button.hint_tooltip = new_button.text
		new_button.clip_text = true
		new_button.connect("pressed", self, "_on_file_button_pressed", [file])
	
	popup_centered_minsize(Vector2(475, 300))


func _clear_buttons():
	$HBoxContainer/ScrollContainer/Content/BackButton.visible = false
	
	for i in range($HBoxContainer/ScrollContainer/Content.get_child_count() - 1, 0, -1):
		$HBoxContainer/ScrollContainer/Content.get_child(i).queue_free()


func _on_file_button_pressed(var file_path):
	_clear_buttons()
	$HBoxContainer/ScrollContainer/Content/BackButton.visible = true
	
	var file = File.new()
	var keys = []
	var content = []
	
	if not file.open(file_path, 1) == OK:
		printerr("[Dialogic] Error opening file at " + file_path + "!")
		show_keys()
		return
		
	var line = file.get_csv_line(",") # get rid of the first line
	var locale_index = _get_locale_index(line)
	
	while file.get_position() < file.get_len():
		line = file.get_csv_line(",")
		keys.append(line[0])
		content.append(line[locale_index])
	
	for i in range(keys.size()):
		var new_button = Button.new()
		$HBoxContainer/ScrollContainer/Content.add_child(new_button)
		new_button.clip_text = true
		new_button.text = keys[i]
		new_button.connect("pressed", self, "_on_key_selected", [keys[i]])
		new_button.connect("mouse_entered", self, "_on_key_hovered", [content[i]])


func _on_key_selected(var key : String):
	emit_signal("key_selected", key)
	hide()


func _on_key_hovered(var content : String):
	$HBoxContainer/KeyContents.text = content


func _get_locale_index(var csv_line : PoolStringArray) -> int:
	var editor_plugin = EditorPlugin.new()
	var editor_settings = editor_plugin.get_editor_interface().get_editor_settings()
	var locale = editor_settings.get('interface/editor/editor_language')
	
	for i in range(csv_line.size()):
		if csv_line[i] == locale:
			editor_plugin.queue_free()
			return i
	
	editor_plugin.queue_free()
	return -1


func _get_translation_files(var base_folder) -> Array:
	var result = []
	
	var dir = Directory.new()
	var err = dir.open(base_folder)
	if not err == OK:
		printerr("[Dialogic] Error loading translations at " + base_folder + "!")
		return result
	
	dir.list_dir_begin(true)
	var file_name : String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			result.append_array(_get_translation_files(base_folder + "/" + file_name))
			file_name = dir.get_next()
			continue
		if file_name.ends_with(".csv"):
			var file_path = base_folder + "/" + file_name
			if _is_translation_csv(file_path):
				result.append(file_path)
			
		file_name = dir.get_next()
	
	return result


func _is_translation_csv(var file_path) -> bool:
	var file := File.new()
	var file_open_result = file.open(file_path, File.READ)
	if file_open_result != OK:
		printerr("error opening file at " + file_path + " for .csv validation!")
		return false
	
	var header = file.get_csv_line(",")
	for i in range(1, header.size(), 1):
		if not valid_locales.has(header[i]):
			return false
	
	return true


func _on_BackButton_pressed() -> void:
	show_keys()


