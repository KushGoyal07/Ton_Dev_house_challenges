contract SimpleDao {
    // Main storage struct
    struct SimpleDao {
        queryId: uint32,
        yesVotes: uint32,
        noVotes: uint32,
        totalVotes: uint32
    }

    // Input structs
    struct RecordVote {
        queryId: uint32,
        vote: bool
    }

    struct ResetVotes {
        queryId: uint32
    }

    // Storage variable
    var storage: SimpleDao = SimpleDao(0, 0, 0, 0)

    // Function selectors
    const RECORD_VOTE_SELECTOR: uint32 = 0xF4A2B1C9
    const RESET_VOTES_SELECTOR: uint32 = 0xD4E7B328

    // Handle internal messages
    fun onInternalMessage(inMsg: InMessage) {
        if (inMsg.body.selector == RECORD_VOTE_SELECTOR) {
            let vote = inMsg.body.decode<RecordVote>()
            if (vote.queryId == storage.queryId) {
                if (vote.vote) {
                    storage.yesVotes = storage.yesVotes + 1
                } else {
                    storage.noVotes = storage.noVotes + 1
                }
                storage.totalVotes = storage.totalVotes + 1
            }
        } elseif (inMsg.body.selector == RESET_VOTES_SELECTOR) {
            let reset = inMsg.body.decode<ResetVotes>()
            if (reset.queryId == storage.queryId) {
                storage.yesVotes = 0
                storage.noVotes = 0
                storage.totalVotes = 0
            }
        }
    }

    // Getter function for votes
    fun getVotes(): (uint32, uint32, uint32) {
        return (storage.yesVotes, storage.noVotes, storage.totalVotes)
    }
}
