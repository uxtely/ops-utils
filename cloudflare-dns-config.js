#!/usr/bin/env node

import readline from 'readline'
import https from "https"


(async () => {
	/* Cloudflare */
	const ZONE_ID = 'enter-the-zone-id' // example.com
	const TOKEN = 'enter-a-token' // Needs Edit Zone DNS Permissions

	const cfAPI = `https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records`

	const DOMAINS = [
		'example.com',
		'my.example.com',
		'free.example.com',
		'blog.example.com'
	]

	const SERVER_A = '192.0.2.10'
	const SERVER_B = '192.0.2.11'

	const rl = readline.createInterface({
		input: process.stdin,
		output: process.stdout,
		prompt: `
Cloudlare A Records
1. Delete Server A
2. Delete Server B
3. Restore Server A 
4. Restore Server B
Type a number: `
	});

	rl.prompt();
	rl.on('line', async line => {
		switch (+line.trim()) {
			case 1:
				return await delete_A_records(SERVER_A)
			case 2:
				return await delete_A_records(SERVER_B)
			case 3:
				return await create_A_records(SERVER_A)
			case 4:
				return await create_A_records(SERVER_B)
			default:
				console.error('Invalid Option');
				rl.close();
		}
	});

	async function create_A_records(ip) {
		console.log('Creating...', ip)
		return Promise.all(DOMAINS.map(d => create_A_record(d, ip)))
	}

	async function delete_A_records(ip) {
		console.log('Deleting', ip)
		const res = await cloudflareAPI('GET', cfAPI)
		const ids = res.result.filter(r => r.content === ip).map(r => r.id)
		return Promise.all(ids.map(id => cloudflareAPI('DELETE', cfAPI + '/' + id)))
	}

	function create_A_record(name, ip) {
		return new Promise((resolve, reject) => {
			const body = JSON.stringify({
				type: 'A',
				name,
				content: ip,
				ttl: 1, // Automatic (500s)
				proxied: false // DNS only (Grey Cloud)
			})

			const req = https.request(cfAPI, {
				method: 'POST',
				headers: {
					'content-type': 'application/json',
					'content-length': Buffer.byteLength(body),
					'authorization': `Bearer ${TOKEN}`
				}

			}, async response => {
				if (response.statusCode !== 200)
					reject(response.statusCode)

				response.setEncoding('utf8')
				let resBody = ''
				response.on('data', chunk => {resBody += chunk})
				response.on('end', () => {
					try { resolve(JSON.parse(resBody)) }
					catch (error) { reject(error) }
				})
			})
			req.on('error', reject)
			req.end(body)
		})
	}

	function cloudflareAPI(method, url) {
		return new Promise((resolve, reject) => {
			const req = https.request(url, {
				method,
				headers: { authorization: `Bearer ${TOKEN}` }
			}, async response => {
				if (response.statusCode !== 200)
					reject(response.statusCode)

				response.setEncoding('utf8')
				let body = ''
				response.on('data', chunk => { body += chunk })
				response.on('end', () => {
					try { resolve(JSON.parse(body)) }
					catch (error) { reject(error) }
				})
			})
			req.on('error', reject)
			req.end()
		})
	}
})()
