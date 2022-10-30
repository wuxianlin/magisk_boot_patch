Apply magisk patch and avb sign boot image with github action
=============================================================

Features
========
- Unpack boot.img/vbmeta.img from rom download url
- Apply magisk patch to boot.img
- Sign magisk.img using avbtool and testkey

Guide
======
1. Fork this repo
1. Go to the **Action** tab in your forked repo
    ![Action Tab](https://docs.github.com/assets/images/help/repository/actions-tab.png)
1. In the left sidebar, click the **Magisk Boot Patch Application** workflow.
    ![Workflow](https://docs.github.com/assets/images/help/repository/actions-quickstart-workflow-sidebar.png)
1. Above the list of workflow runs, select **Run workflow**
    ![Run Workflow](https://docs.github.com/assets/images/actions-workflow-dispatch.png)
1. Input your rom download url, select its cpu abi (mostly arm64-v8a) and click **Run workflow**
    ![Run Workflow](https://docs.github.com/assets/images/actions-manually-run-workflow.png)
1. Wait for the action to complete and download the artifact **DO NOT download it via multithread downloaders like IDM or ADM**
    ![Download](https://docs.github.com/assets/images/help/repository/artifact-drop-down-updated.png)
1. Unzip the artifact named magisk

## Credits

- [MagiskOnWSA](https://github.com/LSPosed/MagiskOnWSA): Magisk On WSA
- [Magisk](https://github.com/topjohnwu/Magisk): The most famous root solution on Android

