/* This is a generated file.  Do not edit. */

using Gee;
using Gdk;

public class StickerSet {

  public class StickerInfo {
    public string resource {set; get;}
    public string tooltip  {set; get;}
    public StickerInfo( string resource, string tooltip ) {
      this.resource = resource;
      this.tooltip  = tooltip;
    }
  }

  private Regex _title_re;

  Array<string>                      categories;
  HashMap<string,Array<StickerInfo>> category_icons;

  public StickerSet() {
    categories     = new Array<string>();
    category_icons = new HashMap<string,Array<StickerInfo>>();
    categories.append_val( _( "Photo and Video" ) );
    categories.append_val( _( "Very Basic" ) );
    categories.append_val( _( "Business" ) );
    categories.append_val( _( "Industry" ) );
    categories.append_val( _( "Mobile" ) );
    categories.append_val( _( "Arrows" ) );
    categories.append_val( _( "Data" ) );
    var array0 = new Array<StickerInfo>();
    array0.append_val( new StickerInfo( "flash_on", _( "Flash on" ) ) );
    array0.append_val( new StickerInfo( "flash_off", _( "Flash off" ) ) );
    array0.append_val( new StickerInfo( "flash_auto", _( "Flash auto" ) ) );
    array0.append_val( new StickerInfo( "panorama", _( "Panorama" ) ) );
    array0.append_val( new StickerInfo( "landscape", _( "Landscape" ) ) );
    array0.append_val( new StickerInfo( "night_landscape", _( "Night landscape" ) ) );
    array0.append_val( new StickerInfo( "sports_mode", _( "Sports mode" ) ) );
    array0.append_val( new StickerInfo( "portrait_mode", _( "Portrait mode" ) ) );
    array0.append_val( new StickerInfo( "night_portrait", _( "Night portrait" ) ) );
    array0.append_val( new StickerInfo( "close_up_mode", _( "Close up mode" ) ) );
    array0.append_val( new StickerInfo( "selfie", _( "Selfie" ) ) );
    array0.append_val( new StickerInfo( "gallery", _( "Gallery" ) ) );
    array0.append_val( new StickerInfo( "stack_of_photos", _( "Stack of photos" ) ) );
    array0.append_val( new StickerInfo( "add_image", _( "Add image" ) ) );
    array0.append_val( new StickerInfo( "edit_image", _( "Edit image" ) ) );
    array0.append_val( new StickerInfo( "remove_image", _( "Remove image" ) ) );
    array0.append_val( new StickerInfo( "compact_camera", _( "Compact camera" ) ) );
    array0.append_val( new StickerInfo( "multiple_cameras", _( "Multiple cameras" ) ) );
    array0.append_val( new StickerInfo( "camera", _( "Camera" ) ) );
    array0.append_val( new StickerInfo( "slr_back_side", _( "SLR back side" ) ) );
    array0.append_val( new StickerInfo( "old_time_camera", _( "Old time camera" ) ) );
    array0.append_val( new StickerInfo( "camera_addon", _( "Camera addon" ) ) );
    array0.append_val( new StickerInfo( "camera_identification", _( "Camera identification" ) ) );
    array0.append_val( new StickerInfo( "start", _( "Start" ) ) );
    array0.append_val( new StickerInfo( "clapperboard", _( "Clapperboard" ) ) );
    array0.append_val( new StickerInfo( "film", _( "Film" ) ) );
    array0.append_val( new StickerInfo( "camcorder", _( "Camcorder" ) ) );
    array0.append_val( new StickerInfo( "camcorder_pro", _( "Camcorder pro" ) ) );
    array0.append_val( new StickerInfo( "webcam", _( "Webcam" ) ) );
    array0.append_val( new StickerInfo( "integrated_webcam", _( "Integrated webcam" ) ) );
    array0.append_val( new StickerInfo( "rotate_camera", _( "Rotate camera" ) ) );
    array0.append_val( new StickerInfo( "switch_camera", _( "Switch camera" ) ) );
    array0.append_val( new StickerInfo( "photo_reel", _( "Photo reel" ) ) );
    array0.append_val( new StickerInfo( "film_reel", _( "Film reel" ) ) );
    array0.append_val( new StickerInfo( "cable_release", _( "Cable release" ) ) );
    category_icons.set( _( "Photo and Video" ), array0 );
    var array1 = new Array<StickerInfo>();
    array1.append_val( new StickerInfo( "home", _( "Home" ) ) );
    array1.append_val( new StickerInfo( "icons8_cup", _( "Icons8 cup" ) ) );
    array1.append_val( new StickerInfo( "globe", _( "Globe" ) ) );
    array1.append_val( new StickerInfo( "ok", _( "OK" ) ) );
    array1.append_val( new StickerInfo( "checkmark", _( "Checkmark" ) ) );
    array1.append_val( new StickerInfo( "cancel", _( "Cancel" ) ) );
    array1.append_val( new StickerInfo( "synchronize", _( "Synchronize" ) ) );
    array1.append_val( new StickerInfo( "refresh", _( "Refresh" ) ) );
    array1.append_val( new StickerInfo( "download", _( "Download" ) ) );
    array1.append_val( new StickerInfo( "upload", _( "Upload" ) ) );
    array1.append_val( new StickerInfo( "empty_trash", _( "Empty trash" ) ) );
    array1.append_val( new StickerInfo( "full_trash", _( "Full trash" ) ) );
    array1.append_val( new StickerInfo( "folder", _( "Folder" ) ) );
    array1.append_val( new StickerInfo( "opened_folder", _( "Opened folder" ) ) );
    array1.append_val( new StickerInfo( "file", _( "File" ) ) );
    array1.append_val( new StickerInfo( "document", _( "Document" ) ) );
    array1.append_val( new StickerInfo( "audio_file", _( "Audio file" ) ) );
    array1.append_val( new StickerInfo( "image_file", _( "Image file" ) ) );
    array1.append_val( new StickerInfo( "video_file", _( "Video file" ) ) );
    array1.append_val( new StickerInfo( "print", _( "Print" ) ) );
    array1.append_val( new StickerInfo( "music", _( "Music" ) ) );
    array1.append_val( new StickerInfo( "share", _( "Share" ) ) );
    array1.append_val( new StickerInfo( "cursor", _( "Cursor" ) ) );
    array1.append_val( new StickerInfo( "puzzle", _( "Puzzle" ) ) );
    array1.append_val( new StickerInfo( "unlock", _( "Unlock" ) ) );
    array1.append_val( new StickerInfo( "lock", _( "Lock" ) ) );
    array1.append_val( new StickerInfo( "idea", _( "Idea" ) ) );
    array1.append_val( new StickerInfo( "no_idea", _( "No idea" ) ) );
    array1.append_val( new StickerInfo( "link", _( "Link" ) ) );
    array1.append_val( new StickerInfo( "broken_link", _( "Broken link" ) ) );
    array1.append_val( new StickerInfo( "rating", _( "Rating" ) ) );
    array1.append_val( new StickerInfo( "like_placeholder", _( "Like placeholder" ) ) );
    array1.append_val( new StickerInfo( "like", _( "Like" ) ) );
    array1.append_val( new StickerInfo( "dislike", _( "Dislike" ) ) );
    array1.append_val( new StickerInfo( "info", _( "Info" ) ) );
    array1.append_val( new StickerInfo( "about", _( "About" ) ) );
    array1.append_val( new StickerInfo( "picture", _( "Picture" ) ) );
    array1.append_val( new StickerInfo( "clock", _( "Clock" ) ) );
    array1.append_val( new StickerInfo( "alarm_clock", _( "Alarm clock" ) ) );
    array1.append_val( new StickerInfo( "address_book", _( "Address book" ) ) );
    array1.append_val( new StickerInfo( "contacts", _( "Contacts" ) ) );
    array1.append_val( new StickerInfo( "news", _( "News" ) ) );
    array1.append_val( new StickerInfo( "bookmark", _( "Bookmark" ) ) );
    array1.append_val( new StickerInfo( "binoculars", _( "Binoculars" ) ) );
    array1.append_val( new StickerInfo( "search", _( "Search" ) ) );
    array1.append_val( new StickerInfo( "ruler", _( "Ruler" ) ) );
    array1.append_val( new StickerInfo( "services", _( "Services" ) ) );
    array1.append_val( new StickerInfo( "settings", _( "Settings" ) ) );
    array1.append_val( new StickerInfo( "support", _( "Support" ) ) );
    array1.append_val( new StickerInfo( "frame", _( "Frame" ) ) );
    array1.append_val( new StickerInfo( "menu", _( "Menu" ) ) );
    array1.append_val( new StickerInfo( "key", _( "Key" ) ) );
    array1.append_val( new StickerInfo( "calendar", _( "Calendar" ) ) );
    array1.append_val( new StickerInfo( "calculator", _( "Calculator" ) ) );
    array1.append_val( new StickerInfo( "minus", _( "Minus" ) ) );
    array1.append_val( new StickerInfo( "plus", _( "Plus" ) ) );
    category_icons.set( _( "Very Basic" ), array1 );
    var array2 = new Array<StickerInfo>();
    array2.append_val( new StickerInfo( "graduation_cap", _( "Graduation cap" ) ) );
    array2.append_val( new StickerInfo( "briefcase", _( "Briefcase" ) ) );
    array2.append_val( new StickerInfo( "business", _( "Business" ) ) );
    array2.append_val( new StickerInfo( "signature", _( "Signature" ) ) );
    array2.append_val( new StickerInfo( "safe", _( "Safe" ) ) );
    array2.append_val( new StickerInfo( "advertising", _( "Advertising" ) ) );
    array2.append_val( new StickerInfo( "businessman", _( "Businessman" ) ) );
    array2.append_val( new StickerInfo( "businesswoman", _( "Businesswoman" ) ) );
    array2.append_val( new StickerInfo( "manager", _( "Manager" ) ) );
    array2.append_val( new StickerInfo( "online_support", _( "Online support" ) ) );
    array2.append_val( new StickerInfo( "assistant", _( "Assistant" ) ) );
    array2.append_val( new StickerInfo( "customer_support", _( "Customer support" ) ) );
    array2.append_val( new StickerInfo( "reading_ebook", _( "Reading ebook" ) ) );
    array2.append_val( new StickerInfo( "reading", _( "Reading" ) ) );
    array2.append_val( new StickerInfo( "neutral_trading", _( "Neutral trading" ) ) );
    array2.append_val( new StickerInfo( "bullish", _( "Bullish" ) ) );
    array2.append_val( new StickerInfo( "bearish", _( "Bearish" ) ) );
    array2.append_val( new StickerInfo( "high_priority", _( "High priority" ) ) );
    array2.append_val( new StickerInfo( "medium_priority", _( "Medium priority" ) ) );
    array2.append_val( new StickerInfo( "low_priority", _( "Low priority" ) ) );
    array2.append_val( new StickerInfo( "make_decision", _( "Make decision" ) ) );
    array2.append_val( new StickerInfo( "decision", _( "Decision" ) ) );
    array2.append_val( new StickerInfo( "good_decision", _( "Good decision" ) ) );
    array2.append_val( new StickerInfo( "neutral_decision", _( "Neutral decision" ) ) );
    array2.append_val( new StickerInfo( "bad_decision", _( "Bad decision" ) ) );
    array2.append_val( new StickerInfo( "approve", _( "Approve" ) ) );
    array2.append_val( new StickerInfo( "disapprove", _( "Disapprove" ) ) );
    array2.append_val( new StickerInfo( "podium_without_speaker", _( "Podium without speaker" ) ) );
    array2.append_val( new StickerInfo( "podium_with_speaker", _( "Podium with speaker" ) ) );
    array2.append_val( new StickerInfo( "podium_with_audience", _( "Podium with audience" ) ) );
    array2.append_val( new StickerInfo( "video_projector", _( "Video projector" ) ) );
    array2.append_val( new StickerInfo( "statistics", _( "Statistics" ) ) );
    array2.append_val( new StickerInfo( "collaboration", _( "Collaboration" ) ) );
    array2.append_val( new StickerInfo( "voice_presentation", _( "Voice presentation" ) ) );
    array2.append_val( new StickerInfo( "conference_call", _( "Conference call" ) ) );
    array2.append_val( new StickerInfo( "comments", _( "Comments" ) ) );
    array2.append_val( new StickerInfo( "faq", _( "FAQ" ) ) );
    array2.append_val( new StickerInfo( "reuse", _( "Reuse" ) ) );
    array2.append_val( new StickerInfo( "organization", _( "Organization" ) ) );
    array2.append_val( new StickerInfo( "department", _( "Department" ) ) );
    array2.append_val( new StickerInfo( "library", _( "Library" ) ) );
    array2.append_val( new StickerInfo( "shop", _( "Shop" ) ) );
    array2.append_val( new StickerInfo( "self_service_kiosk", _( "Self service kiosk" ) ) );
    array2.append_val( new StickerInfo( "donate", _( "Donate" ) ) );
    array2.append_val( new StickerInfo( "currency_exchange", _( "Currency exchange" ) ) );
    array2.append_val( new StickerInfo( "debt", _( "Debt" ) ) );
    array2.append_val( new StickerInfo( "sales_performance", _( "Sales performance" ) ) );
    array2.append_val( new StickerInfo( "invite", _( "Invite" ) ) );
    array2.append_val( new StickerInfo( "money_transfer", _( "Money transfer" ) ) );
    array2.append_val( new StickerInfo( "feedback", _( "Feedback" ) ) );
    array2.append_val( new StickerInfo( "approval", _( "Approval" ) ) );
    array2.append_val( new StickerInfo( "paid", _( "Paid" ) ) );
    array2.append_val( new StickerInfo( "in_transit", _( "In transit" ) ) );
    array2.append_val( new StickerInfo( "shipped", _( "Shipped" ) ) );
    array2.append_val( new StickerInfo( "package", _( "Package" ) ) );
    array2.append_val( new StickerInfo( "planner", _( "Planner" ) ) );
    array2.append_val( new StickerInfo( "overtime", _( "Overtime" ) ) );
    array2.append_val( new StickerInfo( "leave", _( "Leave" ) ) );
    array2.append_val( new StickerInfo( "expired", _( "Expired" ) ) );
    array2.append_val( new StickerInfo( "process", _( "Process" ) ) );
    array2.append_val( new StickerInfo( "diploma_1", _( "Diploma 1" ) ) );
    array2.append_val( new StickerInfo( "diploma_2", _( "Diploma 2" ) ) );
    array2.append_val( new StickerInfo( "business_contact", _( "Business contact" ) ) );
    array2.append_val( new StickerInfo( "survey", _( "Survey" ) ) );
    array2.append_val( new StickerInfo( "inspection", _( "Inspection" ) ) );
    array2.append_val( new StickerInfo( "rules", _( "Rules" ) ) );
    array2.append_val( new StickerInfo( "todo_list", _( "Todo list" ) ) );
    array2.append_val( new StickerInfo( "ratings", _( "Ratings" ) ) );
    array2.append_val( new StickerInfo( "questions", _( "Questions" ) ) );
    array2.append_val( new StickerInfo( "answers", _( "Answers" ) ) );
    array2.append_val( new StickerInfo( "fine_print", _( "Fine print" ) ) );
    array2.append_val( new StickerInfo( "candle_sticks", _( "Candle sticks" ) ) );
    array2.append_val( new StickerInfo( "serial_tasks", _( "Serial tasks" ) ) );
    array2.append_val( new StickerInfo( "parallel_tasks", _( "Parallel tasks" ) ) );
    array2.append_val( new StickerInfo( "tree_structure", _( "Tree structure" ) ) );
    array2.append_val( new StickerInfo( "org_unit", _( "Org unit" ) ) );
    array2.append_val( new StickerInfo( "privacy", _( "Privacy" ) ) );
    array2.append_val( new StickerInfo( "disclaimer", _( "Disclaimer" ) ) );
    array2.append_val( new StickerInfo( "callback", _( "Callback" ) ) );
    array2.append_val( new StickerInfo( "service_mark", _( "Service mark" ) ) );
    array2.append_val( new StickerInfo( "registered_trademark", _( "Registered trademark" ) ) );
    array2.append_val( new StickerInfo( "trademark", _( "Trademark" ) ) );
    array2.append_val( new StickerInfo( "copyright", _( "Copyright" ) ) );
    array2.append_val( new StickerInfo( "copyleft", _( "Copyleft" ) ) );
    array2.append_val( new StickerInfo( "sound_recording_copyright", _( "Sound recording copyright" ) ) );
    array2.append_val( new StickerInfo( "butting_in", _( "Butting in" ) ) );
    array2.append_val( new StickerInfo( "multiple_inputs", _( "Multiple inputs" ) ) );
    array2.append_val( new StickerInfo( "collect", _( "Collect" ) ) );
    array2.append_val( new StickerInfo( "internal", _( "Internal" ) ) );
    array2.append_val( new StickerInfo( "external", _( "External" ) ) );
    array2.append_val( new StickerInfo( "vip", _( "VIP" ) ) );
    array2.append_val( new StickerInfo( "light_at_the_end_of_tunnel", _( "Light at the end of tunnel" ) ) );
    array2.append_val( new StickerInfo( "entering_heaven_alive", _( "Entering heaven alive" ) ) );
    category_icons.set( _( "Business" ), array2 );
    var array3 = new Array<StickerInfo>();
    array3.append_val( new StickerInfo( "biomass", _( "Biomass" ) ) );
    array3.append_val( new StickerInfo( "display", _( "Display" ) ) );
    array3.append_val( new StickerInfo( "do_not_inhale", _( "Do not inhale" ) ) );
    array3.append_val( new StickerInfo( "factory", _( "Factory" ) ) );
    array3.append_val( new StickerInfo( "factory_breakdown", _( "Factory breakdown" ) ) );
    array3.append_val( new StickerInfo( "crystal_oscillator", _( "Crystal oscillator" ) ) );
    array3.append_val( new StickerInfo( "capacitor", _( "Capacitor" ) ) );
    array3.append_val( new StickerInfo( "electricity", _( "Electricity" ) ) );
    array3.append_val( new StickerInfo( "electro_devices", _( "Electro devices" ) ) );
    array3.append_val( new StickerInfo( "electrical_sensor", _( "Electrical sensor" ) ) );
    array3.append_val( new StickerInfo( "electrical_threshold", _( "Electrical threshold" ) ) );
    array3.append_val( new StickerInfo( "automotive", _( "Automotive" ) ) );
    array3.append_val( new StickerInfo( "feed_in", _( "Feed in" ) ) );
    array3.append_val( new StickerInfo( "dam", _( "Dam" ) ) );
    array3.append_val( new StickerInfo( "biotech", _( "Biotech" ) ) );
    array3.append_val( new StickerInfo( "advance", _( "Advance" ) ) );
    array3.append_val( new StickerInfo( "cloth", _( "Cloth" ) ) );
    array3.append_val( new StickerInfo( "electronics", _( "Electronics" ) ) );
    array3.append_val( new StickerInfo( "deployment", _( "Deployment" ) ) );
    array3.append_val( new StickerInfo( "automatic", _( "Automatic" ) ) );
    array3.append_val( new StickerInfo( "do_not_insert", _( "Do not insert" ) ) );
    array3.append_val( new StickerInfo( "do_not_mix", _( "Do not mix" ) ) );
    array3.append_val( new StickerInfo( "biohazard", _( "Biohazard" ) ) );
    array3.append_val( new StickerInfo( "circuit", _( "Circuit" ) ) );
    array3.append_val( new StickerInfo( "engineering", _( "Engineering" ) ) );
    category_icons.set( _( "Industry" ), array3 );
    var array4 = new Array<StickerInfo>();
    array4.append_val( new StickerInfo( "cell_phone", _( "Cell phone" ) ) );
    array4.append_val( new StickerInfo( "iphone", _( "iPhone" ) ) );
    array4.append_val( new StickerInfo( "ipad", _( "iPad" ) ) );
    array4.append_val( new StickerInfo( "phone_android", _( "Phone android" ) ) );
    array4.append_val( new StickerInfo( "tablet_android", _( "Tablet android" ) ) );
    array4.append_val( new StickerInfo( "nook", _( "Nook" ) ) );
    array4.append_val( new StickerInfo( "kindle", _( "Kindle" ) ) );
    array4.append_val( new StickerInfo( "two_smartphones", _( "Two smartphones" ) ) );
    array4.append_val( new StickerInfo( "multiple_devices", _( "Multiple devices" ) ) );
    array4.append_val( new StickerInfo( "multiple_smartphones", _( "Multiple smartphones" ) ) );
    array4.append_val( new StickerInfo( "smartphone_tablet", _( "Smartphone tablet" ) ) );
    array4.append_val( new StickerInfo( "touchscreen_smartphone", _( "Touchscreen smartphone" ) ) );
    array4.append_val( new StickerInfo( "sim_card", _( "Sim card" ) ) );
    array4.append_val( new StickerInfo( "sim_card_chip", _( "Sim card chip" ) ) );
    array4.append_val( new StickerInfo( "sms", _( "SMS" ) ) );
    array4.append_val( new StickerInfo( "mms", _( "MMS" ) ) );
    array4.append_val( new StickerInfo( "charge_battery", _( "Charge battery" ) ) );
    array4.append_val( new StickerInfo( "full_battery", _( "Full battery" ) ) );
    array4.append_val( new StickerInfo( "high_battery", _( "High battery" ) ) );
    array4.append_val( new StickerInfo( "middle_battery", _( "Middle battery" ) ) );
    array4.append_val( new StickerInfo( "low_battery", _( "Low battery" ) ) );
    array4.append_val( new StickerInfo( "empty_battery", _( "Empty battery" ) ) );
    array4.append_val( new StickerInfo( "phone", _( "Phone" ) ) );
    array4.append_val( new StickerInfo( "missed_call", _( "Missed call" ) ) );
    array4.append_val( new StickerInfo( "end_call", _( "End call" ) ) );
    array4.append_val( new StickerInfo( "call_transfer", _( "Call transfer" ) ) );
    array4.append_val( new StickerInfo( "video_call", _( "Video call" ) ) );
    array4.append_val( new StickerInfo( "no_video", _( "No video" ) ) );
    array4.append_val( new StickerInfo( "rotate_to_portrait", _( "Rotate to portrait" ) ) );
    array4.append_val( new StickerInfo( "lock_portrait", _( "Lock portrait" ) ) );
    array4.append_val( new StickerInfo( "rotate_to_landscape", _( "Rotate to landscape" ) ) );
    array4.append_val( new StickerInfo( "lock_landscape", _( "Lock landscape" ) ) );
    array4.append_val( new StickerInfo( "voicemail", _( "Voicemail" ) ) );
    array4.append_val( new StickerInfo( "speaker", _( "Speaker" ) ) );
    array4.append_val( new StickerInfo( "headset", _( "Headset" ) ) );
    category_icons.set( _( "Mobile" ), array4 );
    var array5 = new Array<StickerInfo>();
    array5.append_val( new StickerInfo( "left_up", _( "Left up" ) ) );
    array5.append_val( new StickerInfo( "up", _( "Up" ) ) );
    array5.append_val( new StickerInfo( "right_up", _( "Right up" ) ) );
    array5.append_val( new StickerInfo( "left", _( "Left" ) ) );
    array5.append_val( new StickerInfo( "right", _( "Right" ) ) );
    array5.append_val( new StickerInfo( "left_down", _( "Left down" ) ) );
    array5.append_val( new StickerInfo( "down", _( "Down" ) ) );
    array5.append_val( new StickerInfo( "right_down", _( "Right down" ) ) );
    array5.append_val( new StickerInfo( "collapse", _( "Collapse" ) ) );
    array5.append_val( new StickerInfo( "previous", _( "Previous" ) ) );
    array5.append_val( new StickerInfo( "next", _( "Next" ) ) );
    array5.append_val( new StickerInfo( "expand", _( "Expand" ) ) );
    array5.append_val( new StickerInfo( "left_down2", _( "Left down2" ) ) );
    array5.append_val( new StickerInfo( "up_left", _( "Up left" ) ) );
    array5.append_val( new StickerInfo( "down_right", _( "Down right" ) ) );
    array5.append_val( new StickerInfo( "right_up2", _( "Right up2" ) ) );
    array5.append_val( new StickerInfo( "up_right", _( "Up right" ) ) );
    array5.append_val( new StickerInfo( "right_down2", _( "Right down2" ) ) );
    array5.append_val( new StickerInfo( "left_up2", _( "Left up2" ) ) );
    array5.append_val( new StickerInfo( "down_left", _( "Down left" ) ) );
    array5.append_val( new StickerInfo( "undo", _( "Undo" ) ) );
    array5.append_val( new StickerInfo( "redo", _( "Redo" ) ) );
    category_icons.set( _( "Arrows" ), array5 );
    var array6 = new Array<StickerInfo>();
    array6.append_val( new StickerInfo( "filing_cabinet", _( "Filing cabinet" ) ) );
    array6.append_val( new StickerInfo( "database", _( "Database" ) ) );
    array6.append_val( new StickerInfo( "accept_database", _( "Accept database" ) ) );
    array6.append_val( new StickerInfo( "add_database", _( "Add database" ) ) );
    array6.append_val( new StickerInfo( "delete_database", _( "Delete database" ) ) );
    array6.append_val( new StickerInfo( "data_backup", _( "Data backup" ) ) );
    array6.append_val( new StickerInfo( "data_recovery", _( "Data recovery" ) ) );
    array6.append_val( new StickerInfo( "data_configuration", _( "Data configuration" ) ) );
    array6.append_val( new StickerInfo( "data_encryption", _( "Data encryption" ) ) );
    array6.append_val( new StickerInfo( "data_protection", _( "Data protection" ) ) );
    array6.append_val( new StickerInfo( "grid", _( "Grid" ) ) );
    array6.append_val( new StickerInfo( "data_sheet", _( "Data sheet" ) ) );
    array6.append_val( new StickerInfo( "add_column", _( "Add column" ) ) );
    array6.append_val( new StickerInfo( "delete_column", _( "Delete column" ) ) );
    array6.append_val( new StickerInfo( "add_row", _( "Add row" ) ) );
    array6.append_val( new StickerInfo( "delete_row", _( "Delete row" ) ) );
    array6.append_val( new StickerInfo( "generic_sorting_asc", _( "Generic sorting ascending" ) ) );
    array6.append_val( new StickerInfo( "generic_sorting_desc", _( "Generic sorting descending" ) ) );
    array6.append_val( new StickerInfo( "alphabetical_sorting_az", _( "Alphabetical sorting (A->Z)" ) ) );
    array6.append_val( new StickerInfo( "alphabetical_sorting_za", _( "Alphabetical sorting (Z->A)" ) ) );
    array6.append_val( new StickerInfo( "numerical_sorting_21", _( "Numerical sorting (2->1)" ) ) );
    array6.append_val( new StickerInfo( "numerical_sorting_12", _( "Numerical sorting (1->2)" ) ) );
    array6.append_val( new StickerInfo( "empty_filter", _( "Empty filter" ) ) );
    array6.append_val( new StickerInfo( "filled_filter", _( "Filled filter" ) ) );
    array6.append_val( new StickerInfo( "clear_filters", _( "Clear filters" ) ) );
    array6.append_val( new StickerInfo( "pie_chart", _( "Pie chart" ) ) );
    array6.append_val( new StickerInfo( "radar_plot", _( "Radar plot" ) ) );
    array6.append_val( new StickerInfo( "heat_map", _( "Heat map" ) ) );
    array6.append_val( new StickerInfo( "timeline", _( "Timeline" ) ) );
    array6.append_val( new StickerInfo( "bar_chart", _( "Bar chart" ) ) );
    array6.append_val( new StickerInfo( "area_chart", _( "Area chart" ) ) );
    array6.append_val( new StickerInfo( "scatter_plot", _( "Scatter plot" ) ) );
    array6.append_val( new StickerInfo( "doughnut_chart", _( "Doughnut chart" ) ) );
    array6.append_val( new StickerInfo( "combo_chart", _( "Combo chart" ) ) );
    array6.append_val( new StickerInfo( "flow_chart", _( "Flow chart" ) ) );
    array6.append_val( new StickerInfo( "line_chart", _( "Line chart" ) ) );
    array6.append_val( new StickerInfo( "genealogy", _( "Genealogy" ) ) );
    array6.append_val( new StickerInfo( "mind_map", _( "Mind map" ) ) );
    array6.append_val( new StickerInfo( "workflow", _( "Workflow" ) ) );
    array6.append_val( new StickerInfo( "positive_dynamic", _( "Positive dynamic" ) ) );
    array6.append_val( new StickerInfo( "negative_dynamic", _( "Negative dynamic" ) ) );
    array6.append_val( new StickerInfo( "export", _( "Export" ) ) );
    array6.append_val( new StickerInfo( "import", _( "Import" ) ) );
    array6.append_val( new StickerInfo( "list", _( "List" ) ) );
    array6.append_val( new StickerInfo( "template", _( "Template" ) ) );
    array6.append_val( new StickerInfo( "view_details", _( "View details" ) ) );
    category_icons.set( _( "Data" ), array6 );

    try {
      _title_re = new Regex( "(^|\\W)([a-z])" );
    } catch( RegexError e ) {}

    /* Finally load any user-supplied sticker (if they exist) */
    var base_dir = Path.build_filename( Environment.get_user_data_dir(), "minder", "stickers" );
    load_from_filesystem( base_dir );

  }

  public Array<string> get_categories() {
    return( categories );
  }

  public Array<StickerInfo> get_category_icons( string category ) {
    return( category_icons.get( category ) );
  }

  public bool get_icon_info( string resource, out string tooltip ) {
    tooltip     = "";
    for( int i=0; i<categories.length; i++ ) {
      var icons = category_icons.get( categories.index( i ) );
      for( int j=0; j<icons.length; j++ ) {
        if( icons.index( j ).resource == resource ) {
          tooltip = icons.index( j ).tooltip;
          return( true );
        }
      }
    }
    return( false );
  }

  private void load_from_filesystem( string base_dir ) {
    if( FileUtils.test( base_dir, FileTest.EXISTS ) ) {
      try {
        string? name;
        var dir = Dir.open( base_dir, 0 );
        while( (name = dir.read_name()) != null) {
          var category = Path.build_filename( base_dir, name );
          if( FileUtils.test( category, FileTest.IS_DIR ) ) {
            string? subname;
            var subdir = Dir.open( category, 0 );
            while( (subname = subdir.read_name()) != null ) {
              var sticker = Path.build_filename( category, subname );
              var parts   = subname.split( "." );
              load_sticker( name, parts[0], sticker );
            }
          }
        }
      } catch( FileError e ) {
        stderr.printf( "ERROR: %s\n", e.message );
      }
    }
  }

  private string make_label( string category ) {
    var name = category.replace( "_", " " ).down();
    string[]  parts;
    MatchInfo matches;
    int       start, end;
    while( _title_re.match( name, 0, out matches ) ) {
      matches.fetch_pos( 2, out start, out end );
      name = name.splice( start, end, name.slice( start, end ).up() );
    }
    return( name.replace( "And", "and" ) );
  }

  private void load_sticker( string category, string name, string sticker_file ) {
    int width, height;
    var format = Gdk.Pixbuf.get_file_info( sticker_file, out width, out height );
    if( format != null ) {
      var cat_label    = make_label( category );
      var name_tooltip = name.replace( "_", " " ).splice( 0, name.index_of_nth_char( 1 ), name.slice( 0, name.index_of_nth_char( 1 ) ).up() );
      var sticker_info = new StickerInfo( sticker_file, name_tooltip );
      if( category_icons.has_key( cat_label ) ) {
        var array = category_icons.get( cat_label );
        array.append_val( sticker_info );
      } else {
        var array = new Array<StickerInfo>();
        array.append_val( sticker_info );
        category_icons.set( cat_label, array );
        categories.prepend_val( cat_label );
      }
    }
  }

  public static Gdk.Pixbuf? make_pixbuf( string resource, int width = -1 ) {
    try {
      if( resource.get_char( 0 ) == '/' ) {
        return( new Pixbuf.from_file_at_scale( resource, ((width == -1) ? 64 : width), -1, true ) );
      } else {
        return( new Pixbuf.from_resource_at_scale( ("/com/github/phase1geo/minder/" + resource), ((width == -1) ? 64 : width), -1, true ) );
      }
    } catch( Error e ) {
      return( null );
    }
  }

}
