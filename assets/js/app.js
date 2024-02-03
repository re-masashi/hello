// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
import socket from "./user_socket.js"

// You can include dependencies in two way
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
import {Marked} from 'marked'
import { markedHighlight } from "marked-highlight";
import hljs from 'highlight.js';
import {markedEmoji} from "marked-emoji";
import emojis from "./emojis.json";

console.log(emojis)

const options = {
	emojis,
	unicode: false,
};

window.marked = new Marked(
	markedHighlight({
	  langPrefix: 'hljs language-',
	  highlight(code, lang, info) {
	    const language = hljs.getLanguage(lang) ? lang : 'plaintext';
	    return hljs.highlight(code, { language: language }).value;
	  }
	}),
)

hljs.highlightAll();

const emojiExtension = markedEmoji({
  emojis,
  unicode: false,
});

const emojiRenderer = emojiExtension.extensions[0].renderer;

emojiExtension.extensions[0].renderer = (token)=> {
  const html = emojiRenderer(token);
  return html.replace(/^<img /, '<img class="inline-block "');
}

marked.use(emojiExtension);



const renderer = {
  heading(text, level) {
    const escapedText = text.toLowerCase().replace(/[^\w]+/g, '-');

    let textClass = "text-"

    switch(level){
    case 1:
    	textClass+="4xl"; break;
    case 2:
    	textClass+="3xl"; break;
    case 3:
    	textClass+="xl"; break;
    case 4: 
    	textClass+="lg"; break;
    case 5:
    	textClass+="md"; break;
    case 6:
    	textClass+="sm"; break;
    }

    return `
      <h${level} class="${textClass}">
        ${text}
      </h${level}>`;
  },
  blockquote(quote){
  	return `
  	<div class="
  	  text-sm text-gray-300 border-l-4 mx-2 
  	  border-purple-500 pl-2 py-1 overflow-auto break-all bg-zinc-800">
  	  ${quote}
  	</div>
  	`;
  },
};

window.marked.use({ renderer });

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
import tippy, {animateFill} from 'tippy.js'
// window.WebRTCEndpoint = WebRTCEndpoint
// window.Endpoint = Endpoint
// window.TrackContext= TrackContext

// async function initStream() {
//   try {

//     // Gets our local media from the browser and stores it as a const, stream.
//     const stream = await navigator.mediaDevices.getUserMedia({video: true})
//     // Stores our stream in the global constant, localStream.
//     window.__datalocalStream = stream
//     console.log(stream)

//     let preview = document.getElementById("myvid")
//     // const myMediaSource = new MediaSource(stream);
//     // const url = URL.createObjectURL(stream);
//     // Sets our local video element to stream from the user's webcam (stream).
//     preview.srcObject = stream
//     preview.onpause = (e)=>preview.style.display = 'none'

//     preview.captureStream = preview.captureStream || preview.mozCaptureStream;

//     let recorder = new MediaStream(preview.captureStream());

//   } catch (e) {
//     console.log(e)
//   }
// }

let Hooks = {}

// Hooks.JoinCall = {
//   mounted() {
//     initStream()
//   }
// }

Hooks.MessageForm = {
  mounted() {
    this.el.addEventListener("submit", e => {
    	e.preventDefault()
    	let isReplySet = document.querySelector("#replyprev").getAttribute('data-phx-isset')=="1" 
    	let chatArea = document.querySelector("#message-list")
      let val = this.el.querySelector('input').value
      console.log(isReplySet)
      val = marked.parse(val)
      let ev = [
      	["push",
      		{"value":
      			{
      				"message":val,
      				"reply":`${isReplySet?document.querySelector("#replyval").innerHTML:""}`
      			},
      			"event":"message"
      		}
      	]
      ]
      liveSocket.execJS(this.el, JSON.stringify(ev))
      hideReply()
      this.el.querySelector('input').value = ""
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

// window.MEDIA_CONSTRAINTS= {
//   audio: true,
//   video: { width: 640, height: 360, frameRate: 24 },
// };

// window.LOCAL_ENDPOINT_ID = "local-endpoint";

// window.room = ()=>{
//   return new Room()
// }

// window. getRoomId = ()=> {
//   return document.getElementById("room").dataset.roomId;
// }

// window.setupDisconnectButton = (fun)=> {
//   const disconnectButton = document.getElementById(
//     "disconnect"
//   );
//   disconnectButton.onclick = fun;
// }

// window.elementId = (peerId) =>{
//   return `uhh-${peerId}`;
// }


// window.attachStream =(stream, peerId)=>{
//   const videoId = elementId(peerId, "video");
//   const audioId = elementId(peerId, "audio");

//   let video = document.getElementById(videoId);
//   let audio = document.getElementById(audioId);

//   video.srcObject = stream;
//   audio.srcObject = stream;
// }

// window.addVideoElement = (peerId, label, isLocalVideo)=> {
//   const videoId = elementId(peerId, "video");
//   const audioId = elementId(peerId, "audio");

//   let video = document.getElementById(videoId);
//   let audio = document.getElementById(audioId);

//   if (!video && !audio) {
//     const values = setupVideoFeed(peerId, label, isLocalVideo);
//     video = values.video;
//     audio = values.audio;
//   }

//   video.id = videoId;
//   video.autoplay = true
//   video.playsInline = true;
//   video.muted = true;

//   audio.id = audioId;
//   audio.autoplay = true;
//   if (isLocalVideo) {
//     audio.muted = true;
//   }
// }


// function setParticipantsList(participants){
//   const participantsNamesEl = document.getElementById(
//     "participants-list"
//   );
//   participantsNamesEl.innerHTML =
//     "<b>Participants</b>: " + participants.join(", ");
// }

// window.setParticipantsList = setParticipantsList

// function resizeVideosGrid() {
//   const grid = document.getElementById("videos-grid");

//   const videos = grid.children.length;

//   let videosPerRow;

//   // break points for grid layout
//   if (videos < 2) {
//     videosPerRow = 1;
//   } else if (videos < 5) {
//     videosPerRow = 2;
//   } else if (videos < 7) {
//     videosPerRow = 3;
//   } else {
//     videosPerRow = 4;
//   }

//   let classesToRemove = [];
//   for (const [index, value] of grid.classList.entries()) {
//     if (value.includes("grid-cols")) {
//       classesToRemove.push(value);
//     }
//   }

//   classesToRemove.forEach((className) => grid.classList.remove(className));

//   // add the class to be a default for mobiles
//   grid.classList.add("grid-cols-1");
//   grid.classList.add(`md:grid-cols-${videosPerRow}`);
// }

// window.resizeVideosGrid = resizeVideosGrid

// function setupVideoFeed(peerId, label, isLocalVideo) {
//   const copy = (
//     document.querySelector("#video-feed-template")
//   ).content.cloneNode(true);
//   const feed = copy.querySelector("div[name='video-feed']");
//   const audio = feed.querySelector("audio");
//   const video = feed.querySelector("video");
//   const videoLabel = feed.querySelector(
//     "div[name='video-label']"
//   );

//   feed.id = elementId(peerId, "feed");
//   videoLabel.innerText = label;

//   if (isLocalVideo) {
//     video.classList.add("flip-horizontally");
//   }

//   const grid = document.querySelector("#videos-grid");
//   grid.appendChild(feed);
//   resizeVideosGrid();

//   return { audio, video };
// }

// window.setupVideoFeed =setupVideoFeed

// function removeVideoElement(peerId){
//   document.getElementById(elementId(peerId, "feed"))?.remove();
//   resizeVideosGrid();
// }

// window.removeVideoElement = removeVideoElement

// function setErrorMessage(
//   message = "Cannot connect to server, refresh the page and try again"
// ) {
//   const errorContainer = document.getElementById("videochat-error");
//   if (errorContainer) {
//     errorContainer.innerHTML = message;
//     errorContainer.style.display = "block";
//   }
// }

// window.setErrorMessage = setErrorMessage

// class Room {
//   endpoints = [];
//   displayName;
//   localStream;
//   webrtc;

//   socket;
//   webrtcSocketRefs= [];
//   webrtcChannel;

//   constructor() {
//     this.socket = new Socket("/socket/vcon");
//     this.socket.connect();
//     this.displayName = `ayoteyo`;
//     this.webrtcChannel = this.socket.channel(`room:ayoteyo`);

//     this.webrtcChannel.onError(() => {
//       this.socketOff();
//       window.location.reload();
//     });
//     this.webrtcChannel.onClose(() => {
//       this.socketOff();
//       window.location.reload();
//     });

//     this.webrtcSocketRefs.push(this.socket.onError(this.leave));
//     this.webrtcSocketRefs.push(this.socket.onClose(this.leave));

//     this.webrtc = new WebRTCEndpoint();

//     this.webrtc.on("sendMediaEvent", (mediaEvent) => {
//       this.webrtcChannel.push("mediaEvent", { data: mediaEvent });
//     })
        
//     this.webrtc.on("connected", (endpointId, otherEndpoints) => {
//       this.localStream.getTracks().forEach((track) =>
//         this.webrtc.addTrack(track, this.localStream, {})
//       );

//       this.endpoints = otherEndpoints;
//       this.endpoints.forEach((endpoint) => {
//         this.addVideoElement(endpoint.id, endpoint.metadata.displayName, false);
//       });
//       this.updateParticipantsList();
//     });
//     this.webrtc.on("connectionError", (message) => { throw `Endpoint denied.` });

//     this.webrtc.on("trackReady", (ctx) => {
//       this.attachStream(ctx.stream, ctx.endpoint.id)
//     });
    
//     this.webrtc.on("endpointAdded", (endpoint) => {
//       this.endpoints.push(endpoint);
//       this.updateParticipantsList();
//       this.addVideoElement(endpoint.id, endpoint.metadata.display_name, false);
//     });
    
//     this.webrtc.on("endpointRemoved", (endpoint) => {
//       this.endpoints = this.endpoints.filter((endpoint) => endpoint.id !== endpoint.id);
//       this.removeVideoElement(endpoint.id);
//       this.updateParticipantsList();
//     });
    
//     this.webrtcChannel.on("mediaEvent", (event) =>
//       this.webrtc.receiveMediaEvent(event.data)
//     );
//   }

//   async join () {
//     try {
//       await this.init();
//       setupDisconnectButton(() => {
//         this.leave();
//         window.location.replace("");
//       });
//       console.log("pre join")
//       this.webrtc.connect({ displayName: this.displayName });
//       console.log("joined")
//     } catch (error) {
//       console.error("Error while joining to the room:", error);
//     }
//   };

//   async init () {
//     try {
//       this.localStream = await navigator.mediaDevices.getUserMedia(
//         MEDIA_CONSTRAINTS
//       );
//     } catch (error) {
//       console.error(error);
//       setErrorMessage(
//         "Failed to setup video room, make sure to grant camera and microphone permissions"
//       );
//       throw "error";
//     }

//     addVideoElement(LOCAL_ENDPOINT_ID, "Me", true);
//     attachStream(this.localStream, LOCAL_ENDPOINT_ID);

//     await this.phoenixChannelPushResult(this.webrtcChannel.join());
//   };

//   leave () {
//     this.webrtc.disconnect();
//     this.webrtcChannel.leave();
//     this.socketOff();
//   };

//   socketOff () {
//     this.socket.off(this.webrtcSocketRefs);
//     while (this.webrtcSocketRefs.length > 0) {
//       this.webrtcSocketRefs.pop();
//     }
//   };

//   updateParticipantsList () {
//     const participantsNames = this.endpoints.map((e) => e.metadata.displayName);

//     if (this.displayName) {
//       participantsNames.push(this.displayName);
//     }

//     setParticipantsList(participantsNames);
//   };

//   async phoenixChannelPushResult (push) {
//     return new Promise((resolve, reject) => {
//       push
//         .receive("ok", (response) => resolve(response))
//         .receive("error", (response) => reject(response));
//     });
//   };
// }
tippy('.message', {
	interactive: true,
	trigger: 'click',
	touch: ['hold', 500], // 500ms delay
	content: `
		<button onclick="alert('NO')" 
			class="
				animate-glotext rounded-lg p-2 
				bg-gradient-to-l from-purple-900 to-fuchsia-700 
				font-bold text-white">Delete</button>
		<button onclick="" 
			class="
				animate-glotext rounded-lg p-2 
				bg-gradient-to-l from-purple-900 to-fuchsia-700 
				font-bold text-white">React</button>
		`,
	allowHTML: true,
});
