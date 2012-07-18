$('.dropdown-toggle').dropdown();

//$.Controller('navbar', {
//  init : function(el) {
//
//    $(el).children("li:first").addClass("active");
//    $("#content").html($.View("//tmpl/home.ejs"));
//  },
//  "li click": function(el, ev) {
//    ev.preventDefault();
//    location.hash = "!" + $(el).find("a").attr("href");
//  },
//});

//$("#navbar").navbar();

var sort_fields = function(fields) {
  var default_field_sort = {"title": 1000};

  var f = {500: []};
  for(var i in fields) {
    if(default_field_sort[fields[i]] != undefined) {
      // default sort value exits
      if(f[default_field_sort[i]] == undefined) {
        f[default_field_sort[i]] = [fields[i]];
      } else {
        f[defualt_field_sort[i]].push(fields[i]); 
      }
    } else {
      // no default sort value
      f[500].push(fields[i]);
    }
  }
  // 4: blah, 1; blorp -> blorp, blah
  var result = [];
  for(var i in f) {
    for(n=0;n<f[i].length;n++){
      result.push(f[i][n]);
    }
  }
  return result.reverse();
} 

$.Model('db', {
  findAll: "/db",
  findOne: "/db"
}, {});

$.Controller("search", {
  init : function(el) {
      console.log("ef");
  },
  "click": function(el) {
    var query={q: $('#query', el.parent()).val()};
    db.findAll(query, function(result) {
      var r = result[0]; // what 
      if (r['result'].length == undefined) {
        console.log("null result");
        $("#searchresult").html("<h1>No match</h1>");
        return;
      }
      r.fields = sort_fields(r.fields);
      $("#searchresult").html($.View("tmpl/tracks.ejs", r));
    });
    return(false);
  }
});

$.route(":page/:action/:id");
$.route(":page", {page: "home"});

$.route.bind('change', function(ev, attr, how, newval, oldval) {
  if (attr == "page") {
    var page = newval;
    $("#navbar").find(".active").removeClass("active");
    $("#navbar li a[href='#!"+page+"']").parent().addClass("active");

    switch(newval) {
      case "database":
        switch(ev['target']['action']) {
          case "edit":
            db.findOne({id: ev['target']['id']}, function(result) {   
              var r = result[0]; // FIXME sort 
              $("#content").html($.View("tmpl/database_edit.ejs", {entry: r}));
            });
            break; // edit
          default:
            $("#content").html($.View("tmpl/" + page + ".ejs"));
            $("#search").search();
        };
        break;
      default:
        $("#content").html($.View("tmpl/" + page + ".ejs"));
    }
  }
});




