// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import socket from "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {}
Hooks.MessageForm = {
  mounted() {
    this.el.addEventListener("submit", e => {
    	let chatArea = document.querySelector("#message-list")
    	e.preventDefault()
      	let val = this.el.querySelector('input').value
      	console.log(val)
      	let attr = this.el.getAttribute('data-phx-cb').replace("msgplaceholder", val)
      	liveSocket.execJS(this.el, attr)
      	this.el.querySelector('input').value=""
    })
  }
}


let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// channel.on('shout', function (payload) {
//   console.log(payload)
// });

window.toggleSidebar = ()=>{
	let el= document.getElementById('sidebarbtn')
	let attr = el.getAttribute('data-hidden')=='true'? 'data-show': 'data-hide';
	console.log(attr);
	liveSocket.execJS(el, el.getAttribute(
		attr
	))
	el.setAttribute('data-hidden', el.getAttribute('data-hidden')=='true'? 'false': 'true')
}

window.toggleOnline = ()=>{
	let el= document.getElementById('onlinebtn')
	let attr = el.getAttribute('data-hidden')=='true'? 'data-show': 'data-hide';
	console.log(attr);
	liveSocket.execJS(el, el.getAttribute(
		attr
	))
	el.setAttribute('data-hidden', el.getAttribute('data-hidden')=='true'? 'false': 'true')
}