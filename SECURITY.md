# Security Policy

## Supported versions

There are no released versions yet. This policy will list supported versions once the first release is published.

## Reporting a vulnerability

Please **do not** report security vulnerabilities through public issues.

Use GitHub's private vulnerability reporting: open the repository's **Security** tab and choose **Report a vulnerability**. Include a description, reproduction steps, the affected version or commit, and the potential impact.

You can expect an acknowledgement of your report; fix timelines will be shared once the project has releases.

## Scope notes

Angular Starter generates source code that becomes the developer's own application. Vulnerabilities in the generated code, in the CLI, or in the schematics are in scope. Vulnerabilities in Angular, Tailwind CSS or other upstream projects should be reported to those projects.

Runtime configuration published to end users must always be validated and authorized on the backend; frontend guards alone are not a security boundary.
