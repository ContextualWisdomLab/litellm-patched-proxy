# Third-party notices

`litellm-patched-proxy` is a downstream image and does not relicense the software it packages.

## LiteLLM

The image is based on `ghcr.io/berriai/litellm:v1.84.10` and overlays selected non-`enterprise/` LiteLLM files from immutable `Seongho-Bae/litellm` commits. The LiteLLM repository license for those paths is MIT; the separate `enterprise/` directory has different terms and is not the source of the overlaid files used by this repository.

Upstream notice:

> MIT License
>
> Copyright (c) 2023 Berri AI
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Source license evidence: `BerriAI/litellm@v1.84.10:LICENSE` and `Seongho-Bae/litellm@fce13be05e620bea3e4ba38139c0e878b0842cbe:LICENSE`.

## Other packaged software

Alpine packages, Python packages, npm packages, container-base contents, and other third-party components retain their own licenses and notices. The repository MIT license applies only to ContextualWisdomLab-authored repository source and documentation and does not override those terms.
