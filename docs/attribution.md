# Attribution

OSD-OSD is an independent implementation. It does not include TSBackground or OSDBackground code.

The task sequence launch and error-handling guidance draws on these posts:

- Jörgen Nilsson, [“Error handling in TS without MDT using OSDBackground”](https://ccmexec.com/2016/12/error-handling-in-ts-without-mdt-using-osdbackground/), December 15, 2016. This post describes a guarded task sequence group, success and error groups, and preserving the failed action return code.
- Johan Schrewelius, [“TSBackground for ConfigMgr”](https://ccmexec.com/2019/06/tsbackground-for-configmgr/), June 12, 2019. The post byline says “Johan” and its summary thanks Johan Schrewelius for creating TSBackground. It describes WinPE startup and an unattend `RunSynchronousCommand` for early Windows startup.

The screenshots embedded in [task-sequence-setup.md](task-sequence-setup.md) are linked from CCMEXEC.COM. They are not stored in this repository. The article authors and site retain rights to those images. The captions link to each original post.

The project maintainer also recognizes Johan Arwidmark for the deployment guidance and writing that shaped the maintainer's approach to sharing practical ConfigMgr deployment knowledge. This recognition does not imply that he authored the CCMEXEC posts or endorses this project.

The project adapts ideas and documents its own implementation choices. It does not claim that the source posts' code or products are part of OSD-OSD.
