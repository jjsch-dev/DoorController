<?lsp
if not app.isAuthenticated(request) then
   response:sendredirect"login.lsp"
end

response:setheader("Content-Security-Policy",
   "default-src 'self' https://cdn.jsdelivr.net; script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline' 'unsafe-eval' blob:; style-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; img-src 'self'")
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="manifest" href="manifest.json">
    <link rel="icon" type="image/png" href="images/garage-32.png">
    <script src="/rtl/smq.js" defer></script>
    <script src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js" defer></script>
    <title>Garage Door</title>
    <style>
	body {
	    display: flex;
	    justify-content: center;
	    align-items: center;
	    height: 100vh;
	    margin: 0;
	    font-family: Arial, sans-serif;
	    background-color: #f5f5f5;
	}

	.container {
	    display: flex;
	    flex-direction: column;
	    align-items: center;
	    gap: 20px;
	}

	.led {
	    width: 50px;
	    height: 50px;
	    border-radius: 50%;
	    box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
	}

	.status {
	    font-size: 24px;
	}

	.slider {
	    display: flex;
	    align-items: center;
	    justify-content: center;
	    position: relative;
	    width: 200px;
	    height: 100px;
	    background-color: #ccc;
	    border-radius: 50px;
	    overflow: hidden;
	    cursor: pointer;
	    outline: none;
	    -webkit-tap-highlight-color: transparent;
	}

	.slider-circle {
	    position: absolute;
	    width: 80px;
	    height: 80px;
	    border-radius: 50%;
	    background-color: white;
	    transition: transform 0.3s;
	}

	.slider.closed .slider-circle {
	    transform: translateX(-60px);
	}

	.slider.open .slider-circle {
	    transform: translateX(60px);
	}

	.gauge {
	    position: relative;
	    width: 100px;
	    height: 100px;
	    border-radius: 50%;
	    background: conic-gradient(
		#f00 var(--percent, 0),
		#ddd 0
	    );
	    display: flex;
	    justify-content: center;
	    align-items: center;
	    visibility: hidden;
	}

	.gauge.visible {
	    visibility: visible;
	}

	.gauge span {
	    position: absolute;
	    font-size: 20px;
	}
    </style>
</head>
<body>
    <div x-data="$store.garage" class="container">
	<!-- LED and Status -->
	<div :style="{ backgroundColor: isOpen ? 'red' : 'green' }" class="led"></div>
	<div class="status" x-text="isOpen ? 'Open' : 'Closed'"></div>

	<!-- Slider -->
	<div
	    :class="{ open: isOpen, closed: !isOpen }"
	    class="slider"
	    @mousedown="$store.garage.startOpening()"
	    @mouseup="$store.garage.stopOpening()"
	    @mouseleave="$store.garage.stopOpening()"
	    @touchstart="$store.garage.startOpening()"
	    @touchend="$store.garage.stopOpening()"
	>
	    <div class="slider-circle"></div>
	</div>

	<!-- Countdown Gauge -->
	<div
	    class="gauge"
	    :class="{ 'visible': isHolding }"
	    :style="{ '--percent': `${countdownPercent}%` }"
	>
	    <span x-text="countdown"></span>
	</div>
    </div>

<script>
  window.addEventListener('load', ()=> {
    let myTid;
    let actionOwner=false;
    let countdownTimer;
    // Create an SMQ instance and connect to the broker.
    let smq = SMQ.Client(SMQ.wsURL("smq.lsp"));

    function pub2broker(subtop,data) { smq.pubjson(data,1,subtop); };

    const garage = Alpine.store('garage');
    garage.startOpening = ()=>{
      if(!garage.isHolding)
	pub2broker("startOpening",{isOpen:garage.isOpen});
    };
    garage.stopOpening = ()=>{
      if(actionOwner && garage.isHolding)
	pub2broker("stopOpening",{isOpen:garage.isOpen});
    };

    function stopOpening() {
      if(garage.isHolding) {
	garage.countdown = 1.5;
	garage.countdownPercent = 0;
	clearInterval(countdownTimer);
	garage.isHolding=false;
      }
    };

    smq.onconnect=function(tid) {
      function smqSub(topic,cb) {  smq.subscribe(topic,{"datatype":"json", "onmsg":cb}) };
      myTid=tid;
      smqSub("isOpen", (msg)=> {
	garage.isOpen = msg.isOpen;
	stopOpening()
      });
      smqSub("startOpening", (msg)=> {
	if(garage.isHolding) return;
	if(myTid==msg.ptid)
	  actionOwner=true;
	garage.isHolding = true;
	garage.isOpen = msg.isOpen;
	let startTime = Date.now();
	countdownTimer = setInterval(()=> {
	  if(!garage.isHolding) {
	    clearInterval(countdownTimer);
	    return;
	  }
	  const elapsed = (Date.now() - startTime) / 1000;
	  garage.countdown = Math.max(0, (1.5 - elapsed).toFixed(1));
	  garage.countdownPercent = ((1.5 - garage.countdown) / 1.5) * 100;
	  if(garage.countdown <= 0) {
	    stopOpening();
	    if(myTid==msg.ptid)
	      pub2broker("isOpen",{isOpen:!garage.isOpen});
	  }
	}, 100);
      });
      smqSub("stopOpening", (msg)=> {
	stopOpening();
      });
      pub2broker("ready",{});
      smq.onclose=function(message,canreconnect) {
	stopOpening();
	console.log("Connection closed");
	location.reload()
      };
    };
  });

document.addEventListener('alpine:init', ()=> {
  Alpine.store('garage', {
    isOpen: <?lsp=app.isOpen() and 'true' or 'false'?>,
    isHolding: false,
    countdown: 1.5,
    countdownPercent: 0,
  });
});
</script>
</body>
</html>
