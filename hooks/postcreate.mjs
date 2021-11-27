import { db } from "./firebaseConfig.mjs";
import { logo } from "./asciiLogo.mjs";
import { getRowyApp, registerRowyApp, logError } from "./createRowyApp.mjs";
import { getTerraformOutput } from "./terminalUtils.mjs";

async function start() {
  try {
    const terraformOutput = await getTerraformOutput("terraform");
    console.log({ terraformOutput });
    const { rowy_run_url, owner_email, rowy_hooks_url } = terraformOutput;

    const rowyRunUrl = rowy_run_url.value;
    const rowyHooksUrl = rowy_hooks_url.value;
    const ownerEmail = owner_email.value;
    const projectId = process.env.GOOGLE_CLOUD_PROJECT;
    const rowyAppURL = `https://${projectId}.rowy.app/setup?rowyRunUrl=${rowyRunUrl}`;
    const publicSettings = {
      signInOptions: ["google"],
    };
    await db.doc("_rowy_/publicSettings").set(publicSettings, { merge: true });

    const userManagement = {
      owner: {
        email: ownerEmail,
      },
    };

    await db.doc("_rowy_/userManagement").set(userManagement, { merge: true });

    const firebaseConfig = await getRowyApp(projectId);
    const { success, message } = await registerRowyApp({
      ownerEmail: ownerEmail,
      firebaseConfig,
      rowyRunUrl,
      service: {
        hooks: rowyHooksUrl,
      },
    });
    if (!success && message !== "project already exists")
      throw new Error(message);
    console.log(logo);
    console.log(
      `
  🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩
  🟩  🎊  Successfully deployed Rowy Run 🎊                                                  🟩
  🟩                                                                                       🟩
  🟩  Continue the setup process by going to the link below:                               🟩
  🟩  👉 ${rowyAppURL}  🟩
  🟩                                                                                       🟩
  🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩`
    );
  } catch (error) {
    console.log(error);
    await logError({
      event: "post-create",
      error: error.message,
    });
    throw new Error(error.message);
  }
}

start();
