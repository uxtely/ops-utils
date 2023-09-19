#!/usr/bin/env node

import https from 'https'
import { execSync } from 'child_process'

// https://blog.uidrafter.com/health-checking-dns-load-balanced-web-servers

const LocationServersIPv4s = [
	'192.0.2.10',
	'192.0.2.11'
]

const HealthCheckURLs = [
	'https://example.com',
	'https://blog.example.com',
	'https://my.example.com/health-check'
]

const HealthCheckPoints = []
for (const addr of LocationServersIPv4s)
	for (const url of HealthCheckURLs)
		HealthCheckPoints.push([addr, url])


Promise.all(HealthCheckPoints.map(([addr, url]) => isOk(url, addr)))
	.then(() => console.log('All OK'))
	.catch(error => {
		console.error('Error', error.toString())
		const fromEmail = 'userfrom@example.com'
		const toEmail = 'userto@example.com'
		const emailBody = error.toString()
		execSync(`echo ${emailBody} | mail -r ${fromEmail} -s "Issue: Health Check" ${toEmail}`)
	})


// The lookup() overrides the OS's resolver so we can target
// the server by IP while using the DNS name (for SSL purposes)
function isOk(url, ip) {
	return new Promise((resolve, reject) => {
		const IPv4 = 4
		const req = https.request(url,
			{
				method: 'HEAD',
				lookup(_, options, resolveDNS) {
					if (options.all)
						resolveDNS(null, [{ address: ip, family: IPv4 }]) // Node 20
					else
						resolveDNS(null, ip, IPv4) // Node 16
				},
				headers: { 'User-Agent': 'HealthCheckBot' },
				timeout: 2000
			},
			response => {
				if (response.statusCode === 200)
					resolve([ip, url])
				else
					reject([req.connection.remoteAddress, url, response.statusCode])
			})
		req.on('error', reject)
		req.on('timeout', reject)
		req.end()
	})
}

