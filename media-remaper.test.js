import { strictEqual, throws } from 'assert'
import { remapMedia } from './media-remaper.js'


const mHashes = new Map([
	['alpha.png', '0xFA.png'],
	['beta.png', '0xFB.png'],
	['chi.png', '0xFC.png']
])

throws(() => remapMedia(mHashes, `<video src="media/missing.mp4">`))

strictEqual(remapMedia(mHashes, `
<img src="media/alpha.png">
<img src="media/alpha.png">
<img src="media/beta.png">
<video poster="media/chi.png">`),
	`
<img src="media/0xFA.png">
<img src="media/0xFA.png">
<img src="media/0xFB.png">
<video poster="media/0xFC.png">`)

