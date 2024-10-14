import { EC2Client, StopInstancesCommand } from "@aws-sdk/client-ec2";

export const handler = async () => {
  const { REGION, SERVER_INSTANCE_ID } = process.env;

  if (!REGION) {
    return {
      statusCode: 500,
      message: 'No region provided',
    };
  }

  if (!SERVER_INSTANCE_ID) {
    return {
      statusCode: 500,
      message: 'No server instance provided',
    };
  }

  const client = new EC2Client({ region: REGION });
  const command = new StopInstancesCommand({
    InstanceIds: [SERVER_INSTANCE_ID],
  });

  try {
    const { StoppingInstances } = await client.send(command);

    return {
      statusCode: 200,
      data: StoppingInstances
    }
  } catch (e) {
    return {
      statusCode: 500,
      message: `Error sending stop command. ${e.message}`,
    };
  }
}
