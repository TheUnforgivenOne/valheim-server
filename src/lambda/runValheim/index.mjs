import { SendCommandCommand, SSMClient } from '@aws-sdk/client-ssm';

export const handler = async () => {
  const { REGION, SERVER_INSTANCE_ID, EC2_USER } = process.env;

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

  if (!EC2_USER) {
    return {
      statusCode: 500,
      message: 'No user provided',
    };
  }

  const client = new SSMClient({ region: REGION });

  const command = new SendCommandCommand({
    DocumentName: 'AWS-RunShellScript',
    InstanceIds: [SERVER_INSTANCE_ID],
    Parameters: {
      commands: [
        'echo "hello" > test.txt',
      ],
      workingDirectory: [`/home/${EC2_USER}`],
    },
  });

  try {
    const result = await client.send(command);
    
    return {
      statusCode: 200,
      data: result
    }
  } catch (e) {
    return {
      statusCode: 500,
      message: `Error sending shell command. ${e.message}`,
    };
  }
};
