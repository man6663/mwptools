namespace JsonIO
{
    public Mission? [] read_json_file(string fn)
    {
        try
        {
            string s;
            if(FileUtils.get_contents(fn, out s))
                return from_json(s);
        } catch {}

        return {};
    }

	private Mission? parse_segment(Json.Object obj) {
		var ms = new Mission();
		foreach (var name in obj.get_members ()) {
			switch (name)
			{
			case "mission":
				MissionItem [] mi={};
				foreach (var rsnode in
						 obj.get_array_member ("mission").get_elements())
				{
					var rsitem = rsnode.get_object ();
					var m = MissionItem();
					m.no = (int) rsitem.get_int_member("no");
					m.action =  MSP.lookup_name(rsitem.get_string_member("action"));
					m.lat = rsitem.get_double_member("lat");
					m.lon = rsitem.get_double_member("lon");
					m.alt = (int) rsitem.get_int_member("alt");
					if(m.alt > ms.maxalt)
						ms.maxalt = m.alt;
					m.param1 = (int) rsitem.get_int_member("p1");
					m.param2 = (int) rsitem.get_int_member("p2");
					m.param3 = (int) rsitem.get_int_member("p3");
					if(rsitem.has_member("flag"))
						m.flag = (uint8) rsitem.get_int_member("flag");
					if(m.action != MSP.Action.RTH && m.action != MSP.Action.JUMP &&
					   m.action != MSP.Action.SET_HEAD)
					{
						if (m.lat > ms.maxy)
							ms.maxy = m.lat;
						if (m.lon > ms.maxx)
							ms.maxx = m.lon;
						if (m.lat <  ms.miny)
							ms.miny = m.lat;
						if (m.lon <  ms.minx)
							ms.minx = m.lon;
					}
					mi += m;
				}
				ms.set_ways(mi);
				ms.update_meta(mi);
				break;
			case "meta":
				var msobj = obj.get_object_member("meta");
				parse_meta(msobj, ref ms);
				break;
			}
		}
		return ms;
	}


    public Mission? [] from_json(string s)
    {
		Mission[] msx = {};
		try {
			var parser = new Json.Parser ();
			parser.load_from_data (s);

			Json.Node root = parser.get_root ();
			Json.Object obj = null;
			if(root!= null && !root.is_null())
				obj = root.get_object ();
			if(obj != null) {
				Json.Node? node;
				node = obj.get_member("missions");
				if (node != null) {
					foreach (var mmnode in
							 obj.get_array_member ("missions").get_elements())
					{
						var mmitem = mmnode.get_object ();
						var ms =  parse_segment(mmitem);
						msx += ms;
					}
				} else {
					var ms =  parse_segment(obj);
					msx += ms;
				}
			}
		} catch {}

		return msx;
    }

    private static void parse_meta(Json.Object o, ref Mission ms)
    {
        foreach (var name in o.get_members())
        {
            switch (name)
            {
                case "zoom":
                    ms.zoom = (int)o.get_int_member("zoom");
                    break;
                case "cx":
                    ms.cx = o.get_double_member("cx");
                    break;
                case "cy":
                    ms.cy = o.get_double_member("cy");
                    break;
                case "home-x":
                    ms.homex = o.get_double_member("home-x");
                    break;
                case "home-y":
                    ms.homey = o.get_double_member("home-y");
                    break;
                case "details":
                    var dobj = o.get_object_member("details");
                    parse_details(dobj, ref ms);
                    break;
            }
        }
    }

    private static void parse_details(Json.Object o, ref Mission ms)
    {
        Json.Object dobj;
        foreach (var name in o.get_members())
        {
            switch (name)
            {
                case "distance":
                    dobj = o.get_object_member("distance");
                    if(dobj.has_member("value"))
                        ms.dist = dobj.get_double_member("value");
                    break;
                case "nav-speed":
                    dobj = o.get_object_member("nav-speed");
                    if(dobj.has_member("value"))
                        ms.nspeed = dobj.get_double_member("value");
                    break;
                case "fly-time":
                    dobj = o.get_object_member("fly-time");
                    if(dobj.has_member("value"))
                        ms.et = (int)dobj.get_int_member("value");
                    break;
                case "loiter-time":
                dobj = o.get_object_member("loiter-time");
                if(dobj.has_member("value"))
                    ms.lt = (int)dobj.get_int_member("value");
                break;
            }
        }
    }

	private void encode_mission(Json.Builder builder, Mission ms) {
        builder.set_member_name ("meta");
        builder.begin_object ();
        builder.set_member_name ("save-date");
        time_t currtime;
        time_t(out currtime);
        builder.add_string_value(Time.local(currtime).format("%FT%T%z"));
        builder.set_member_name ("cx");
        builder.add_double_value (ms.cx);
        builder.set_member_name ("cy");
        builder.add_double_value (ms.cy);
        builder.set_member_name ("details");
        builder.begin_object ();
        builder.set_member_name ("distance");
        builder.add_double_value (ms.dist);
        builder.end_object (); // details
        builder.set_member_name ("generator");
        builder.add_string_value ("mwp");
        builder.end_object (); // meta
        builder.set_member_name ("mission");
        builder.begin_array ();
			var wpno = 1;
			foreach (MissionItem m in ms.get_ways()) {
				builder.begin_object (); //mi
				builder.set_member_name ("no");
				builder.add_int_value (wpno++);
				builder.set_member_name ("action");
				builder.add_string_value(MSP.get_wpname(m.action));
				builder.set_member_name ("lat");
				builder.add_double_value( m.lat);
				builder.set_member_name ("lon");
				builder.add_double_value( m.lon);
				builder.set_member_name ("alt");
				builder.add_int_value( m.alt);
				builder.set_member_name ("p1");
				builder.add_int_value( m.param1);
				builder.set_member_name ("p2");
				builder.add_int_value( m.param2);
				builder.set_member_name ("p3");
				builder.add_int_value( m.param3);
				builder.set_member_name ("flag");
				builder.add_int_value( m.flag);
				builder.end_object (); // mi
			}
			builder.end_array ();
	}

    public string? to_json(Mission []msx, bool indent=true)
    {
		var builder = new Json.Builder ();
		builder.begin_object ();
		if (msx.length == 1) {
			encode_mission(builder, msx[0]);
		} else {
			builder.set_member_name ("missions");
			builder.begin_array ();
			foreach (var ms in msx) {
				builder.begin_object ();
				encode_mission(builder, ms);
				builder.end_object ();
			}
			builder.end_array ();
		}
		builder.end_object (); // root
        var generator = new Json.Generator ();
        if(indent)
        {
            generator.indent = 1;
            generator.indent_char = ' ';
        }
        generator.set_pretty(indent);
        var root = builder.get_root ();
        generator.set_root (root);
        return generator.to_data (null);
    }

    public static void to_json_file(string fn, Mission [] msx)
    {
        var s = to_json(msx, false);
        try {
            FileUtils.set_contents(fn,s);
        } catch (Error e) {
            stderr.puts(e.message);
            stderr.putc('\n');
        }
    }
}

#if JSON_TEST_MAIN
int main (string[] args) {

    if (args.length < 2) {
        stderr.printf ("Argument required!\n");
        return 1;
    }

    Mission []msx;
    msx = JsonIO.read_json_file (args[1]);
	foreach (var ms in msx) {
        ms.dump(120);
        double d;
        int lt;
        var res = ms.calculate_distance(out d, out lt);
        if (res == true)
        {
            var et = (int)(d / 3.0);
            print("calc dist %.1f %ds (%ds)\n",d,et,lt);
        }
        else
            print("Indeterminate\n");
    }
	if (args.length == 3)
		JsonIO.to_json_file(args[2], msx);
	return 0;
}
#endif
