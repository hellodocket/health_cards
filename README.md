# HealthCards

This repository includes a Ruby gem for [SMART Health Cards](https://smarthealth.cards/).

This rips out all of the Rails cruft that led to 120+ supply chain vulnerabilities in https://github.com/dvci/health_cards

It's as minimal as it's going to get, and hopefully it stays this way.

## Reference Implementation

The reference implementation is a Ruby on Rails application with Issuer capabilities for creating SMART Health Cards and Verifier capabilities for confirming an individual's vaccination status or laboratory test results.

This Issuer supports the three defined [methods of retrieving a SMART Health Card](https://spec.smarthealth.cards/#user-retrieves-health-cards):

* via a `*.smart-health-card` file
* via a QR code
* via FHIR `$health-card-issue` operation

The Verifier supports scanning QR codes.

### System Requirements
 - Ruby 3.2 (prior versions may work but are not tested)
 - [Bundler](https://bundler.io)

## Health Cards Gem

Health Cards is a Ruby gem that implements [SMART Health Cards](https://smarthealth.cards), a framework for sharing verifiable clinical data with [HL7 FHIR](https://hl7.org/FHIR/) and [JSON Web Signatures (JWS)](https://datatracker.ietf.org/doc/html/rfc7515) which may then be embedded into a QR code, exported to a `*.smart-health-card` file, or returned by a `$health-card-issue` FHIR operation.

This library also natively supports [SMART Health Cards: Vaccination & Testing Implementation Guide](https://vci.org/ig/vaccination-and-testing) specific cards.

### Installation

Add this line to your application's Gemfile:

```ruby
gem "health_cards", "~> 1.2", git: "https://github.com/hellodocket/health_cards", branch: "feature/lib-only-openssl3"
```

And then execute:

```
 $ bundle install
```

### Documentation

See usage examples in [USAGE.md](https://github.com/dvci/health_cards/blob/main/lib/USAGE.md). 

See full documentation in [API.md](https://github.com/dvci/health_cards/blob/main/lib/API.md).

## Contributing

Feel free to open a PR to this repo or file an issue.

## License

Copyright 2021 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
```
http://www.apache.org/licenses/LICENSE-2.0
```
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Code of Conduct

Everyone interacting in the HealthCards project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/dvci/health_cards/blob/main/CODE_OF_CONDUCT.md).
