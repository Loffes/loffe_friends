// Friendlist
var friends = {}

function confirmRemove(id) {
    swal({
        text: `Do you want to remove ${friends[id].name} from your friendlist?`,
        buttons: ["No", "Yes"],
        dangerMode: true
    }).then((remove) => {
        if (remove) removeFriend(id)
    })
}

function removeFriend(id) {
    if (!friends[id]) return

    fetch(`https://${GetParentResourceName()}/remove_friend`, {
        method: "POST",
        body: JSON.stringify(id.substring("friend-".length))
    }).then(res => res.json().then(res => {
        if (res) {
            delete friends[id]
            refreshFriends()
        }
    }))
}

function insertFriend(id, name, date) {
    friends[`friend-${id}`] = {
        name: name,
        date: new Date(date)
    }
    refreshFriends()
}

function refreshFriends() {
    const element = document.getElementById("friends")
    for (let friend of element.children) {
        if (friend.id && !friends[friend.id]) friend.remove() 
    }
    Object.entries(friends).forEach(entry => {
        const [id, friend] = entry
        const exists = document.getElementById(id)
        if (!exists) 
            element.innerHTML += `
                <div class="friend" id="${id}">
                    <p>
                        <b>Name: </b>${friend.name}
                    </p>
                    <p>
                        <b>Added: </b>${friend.date.toLocaleString()}
                    </p>
                    <p class="remove" onclick="confirmRemove('${id}')">
                        <i class="fa-solid fa-person-circle-minus"></i>
                        Remove friend
                    </p>
                </div>
            `
    })
}

// Add friend
var sentRequests = {}

function sendRequest() {
    const id = document.getElementById("friendid").value
    if (id == "" || id <= 0) return

    fetch(`https://${GetParentResourceName()}/send_request`, {
        method: "POST",
        body: id
    }).then(res => res.json().then(res => {
        if (res.added) insertSent(res.id, res.name)
    }))
}

function cancelRequest(id) {
    if (!sentRequests[id]) return

    fetch(`https://${GetParentResourceName()}/cancel_request`, {
        method: "POST",
        body: JSON.stringify(id.substring("sentRequest-".length))
    }).then(res => res.json().then(res => {
        if (res) {
            delete sentRequests[id]
            refreshSent()
        }
    }))
}

function insertSent(id, name) {
    sentRequests[`sentRequest-${id}`] = name
    refreshSent()
}

function refreshSent() {
    const element = document.getElementById("add")
    for (let request of element.children) {
        if (request.id && !sentRequests[request.id]) request.remove() // remove the request from div if it no longer exists
    }
    Object.entries(sentRequests).forEach(entry => {
        const [id, name] = entry
        const exists = document.getElementById(id)
        if (!exists) 
            element.innerHTML += `
            <div class="friend" id="${id}">
                <p>
                    <b>Name: </b>${name}
                </p>
                <p class="remove" onclick="cancelRequest('${id}')">
                    <i class="fa-solid fa-person-circle-minus"></i>
                    Cancel request
                </p>
            </div>
            `
    })
}

// Friend requests
var requests = {}

function acceptRequest(id) {
    if (!requests[id]) return
    
    fetch(`https://${GetParentResourceName()}/accept_request`, {
        method: "POST",
        body: JSON.stringify(id.substring("request-".length))
    }).then(res => res.json().then(res => {
        if (res) {
            delete requests[id]
            refreshRequests()
        }
    }))
}

function removeRequest(id) {
    if (!requests[id]) return
    
    fetch(`https://${GetParentResourceName()}/deny_request`, {
        method: "POST",
        body: JSON.stringify(id.substring("request-".length))
    }).then(res => res.json().then(res => {
        if (res) {
            delete requests[id]
            refreshRequests()
        }
    }))
}

function insertRequest(id, name) {
    requests[`request-${id}`] = name
    refreshRequests()
}

function refreshRequests() {
    const element = document.getElementById("requests")
    for (let request of element.children) {
        if (request.id && !requests[request.id]) request.remove() // remove the request from div if it no longer exists
    }
    Object.entries(requests).forEach(entry => {
        const [id, name] = entry
        const exists = document.getElementById(id)
        if (!exists) 
            element.innerHTML += `
            <div class="friend" id="${id}">
                <p>
                    <b>Name: </b>${name}
                </p>
                <p class="accept" onclick="acceptRequest('${id}')">
                    <i class="fa-solid fa-person-circle-plus"></i>
                    Accept request
                </p>
                <p class="remove" onclick="removeRequest('${id}')">
                    <i class="fa-solid fa-person-circle-minus"></i>
                    Deny request
                </p>
            </div>
            `
    })
}

// Switching page
var currentTab = ""
function toggleView(tab) {
    if (tab == currentTab) return

    const currentElement = document.getElementById(currentTab)
    const newElement = document.getElementById(tab)

    if(currentElement) currentElement.classList.add("hidden")
    newElement.classList.remove("hidden")

    const currentButton = document.getElementById(currentTab + "-button")
    const newButton = document.getElementById(tab + "-button")
    
    if (currentButton) currentButton.classList.remove("highlighted")
    newButton.classList.add("highlighted")

    currentTab = tab
}

// Initial load
window.onload = () => {
    toggleView("friends")
}

// Communication with script
function toggleUI(visible) {
    if (visible) 
        document.getElementById("main").classList.remove("hidden")
    else 
        document.getElementById("main").classList.add("hidden")
}

window.addEventListener("message", event => {
    const data = event.data
    const friend = data.friend, request = data.request, sentRequest = data.sentRequest
    if (data.message == "open") 
        toggleUI(true)
    else if (data.message == "close")
        toggleUI(false)
    else if (data.message == "add") {
        if (friend) insertFriend(friend.id, friend.name, friend.date)
        if (request) insertRequest(request.id, request.name)
        if (sentRequest) insertSent(sentRequest.id, sentRequest.name)
    } else if (data.message == "remove") {
        if (friend) {
            delete friends[`friend-${friend}`]
            refreshFriends()
        }
        if (request) {
            delete requests[`request-${request}`]
            refreshRequests()
        }
        if (sentRequest) {
            delete sentRequests[`sentRequest-${sentRequest}`]
            refreshSent()
        }
    }
})

document.addEventListener("keydown", event => {
    if (event.key == "Escape") fetch(`https://${GetParentResourceName()}/close`)
})