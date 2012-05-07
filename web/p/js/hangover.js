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

$.Model('Tracks', {
  search: function(){           // find
    alert("hello");
  },
  findAll: "GET /tracks.json"
});

var tracks = new Tracks;
Tracks.findAll({});

$.Controller("TracksController", {
  init : function(el) {
    console.log("trackscontrol");
  },

});

$.route(":page", {page: "home"});

$.route.bind('change', function(ev, attr, how, newval, oldval) {
  if (attr == "page") {
    var page = newval;
    $("#navbar").find(".active").removeClass("active");
    $("#navbar li a[href='#!"+page+"']").parent().addClass("active")
    $("#content").html($.View("tmpl/" + page + ".ejs"));
  }
});


