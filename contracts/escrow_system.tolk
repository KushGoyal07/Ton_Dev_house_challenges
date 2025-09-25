contract EscrowSystem {
    // Main storage struct
    struct EscrowSystem {
        owner: address,
        recipient: address,
        amount: uint64,
        isReleased: bool,
        isRequested: bool
    }

    // Message structs with selectors
    struct (0xE3D2C1B4) InitializeEscrow {
        queryId: uint32,
        recipient: address,
        amount: uint64
    }

    struct (0xF4E3D2C1) RequestFunds {
        queryId: uint32
    }

    struct (0xA1B2C3D4) ReleaseFunds {
        queryId: uint32
    }

    struct (0xB1C2D3E4) CancelEscrow {
        queryId: uint32
    }

    // Storage variable
    var storage: EscrowSystem = EscrowSystem(address(0), address(0), 0, false, false)

    // Handle internal messages
    fun onInternalMessage(inMsg: InMessage) {
        if (inMsg.body.selector == 0xE3D2C1B4) {
            let init = inMsg.body.decode<InitializeEscrow>()
            // Ensure escrow is not already initialized
            assert(storage.owner == address(0), 101) // Error: Already initialized
            // Ensure amount is valid and matches incoming value
            assert(inMsg.value >= init.amount, 102) // Error: Insufficient funds
            assert(init.amount > 0, 103) // Error: Invalid amount
            storage = EscrowSystem(
                inMsg.senderAddress, // Set owner to sender
                init.recipient,
                init.amount,
                false,
                false
            )
        } elseif (inMsg.body.selector == 0xF4E3D2C1) {
            let req = inMsg.body.decode<RequestFunds>()
            // Only recipient can request funds
            assert(inMsg.senderAddress == storage.recipient, 104) // Error: Not recipient
            assert(!storage.isRequested, 105) // Error: Already requested
            assert(!storage.isReleased, 106) // Error: Already released
            storage.isRequested = true
        } elseif (inMsg.body.selector == 0xA1B2C3D4) {
            let release = inMsg.body.decode<ReleaseFunds>()
            // Only owner can release funds
            assert(inMsg.senderAddress == storage.owner, 107) // Error: Not owner
            assert(storage.isRequested, 108) // Error: Not requested
            assert(!storage.isReleased, 109) // Error: Already released
            storage.isReleased = true
            // Send funds to recipient
            let msg = createMessage({
                bounce: false,
                dest: storage.recipient,
                value: storage.amount
            })
            msg.send(0) // Send with default mode
        } elseif (inMsg.body.selector == 0xB1C2D3E4) {
            let cancel = inMsg.body.decode<CancelEscrow>()
            // Only owner can cancel
            assert(inMsg.senderAddress == storage.owner, 110) // Error: Not owner
            assert(!storage.isReleased, 111) // Error: Already released
            storage.isReleased = true // Mark as terminated
            // Refund to owner
            let msg = createMessage({
                bounce: false,
                dest: storage.owner,
                value: storage.amount
            })
            msg.send(0) // Send with default mode
        }
    }

    // Getter function for escrow details
    get fun getEscrowDetails(): (address, address, uint64, bool, bool) {
        return (storage.owner, storage.recipient, storage.amount, storage.isReleased, storage.isRequested)
    }
}
