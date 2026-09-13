import { VStack } from "@astryxdesign/core/Layout";
import wordmark from "./assets/muse-wordmark.png";
import { Heading, Text } from "@astryxdesign/core/Text";
import { Button } from "@astryxdesign/core/Button";
import { TextInput } from "@astryxdesign/core/TextInput";
import { List, ListItem } from "@astryxdesign/core/List";
import { Center } from "@astryxdesign/core/Center";
import type { Connector } from "./api";

type Props = {
  step: number;
  busy: boolean;
  status: string;
  phone: string;
  code: string;
  name: string;
  pin: string;
  connectors: Connector[];
  linked: string[];
  onPhone: (v: string) => void;
  onCode: (v: string) => void;
  onName: (v: string) => void;
  onPin: (v: string) => void;
  onToggleLink: (id: string) => void;
  onContinuePhone: () => void;
  onConfirmCode: () => void;
  onBackToPhone: () => void;
  onContinueAccount: () => void;
  onContinueConnectors: () => void;
  onActivate: () => void;
  onAcceptTos: () => void;
  onOpenLegal: () => void;
};

// Mobile-only auth funnel matching the original Aura phone flow.
export default function AuthScreen(p: Props) {
  return (
    <Center axis="both" padding={0} style={{ minHeight: "100%", width: "100%", background: "#F9FBFC" }}>
      <VStack gap={0} hAlign="center" style={{ width: "100%", maxWidth: 430, paddingLeft: 27, paddingRight: 27 }}>
        <VStack gap={2} hAlign="center" style={{ marginTop: 170 }}>
            <img src={wordmark} alt="Muse" style={{ width: 150, marginTop: 0, marginBottom: 0 }} />
          <Heading level={1} style={{ fontSize: 30, color: "#000000" }}>Welcome to Muse</Heading>
        </VStack>
        <VStack gap={3} style={{ width: "100%", marginTop: 19 }}>
          {p.step === 0 && (
            <VStack gap={2} style={{ width: "100%" }}>
              <TextInput label="Mobile number or email" isLabelHidden value={p.phone} onChange={p.onPhone} placeholder="Mobile number or email" width="100%" />
              <Text color="secondary">You may receive SMS notifications from us by using your mobile number. <Text color="primary">Learn more</Text></Text>
              <Button label="Continue" variant="primary" isLoading={p.busy} isDisabled={!p.phone.trim()} onClick={p.onContinuePhone} />
            </VStack>
          )}
          {p.step === 1 && (
            <VStack gap={2} style={{ width: "100%" }}>
              <Heading level={2} style={{ fontSize: 30, color: "#000000" }}>Enter your code</Heading>
              <TextInput label="6-digit code" isLabelHidden value={p.code} onChange={p.onCode} placeholder="123456" />
              {p.status ? <Text color="secondary">{p.status}</Text> : null}
              <Button label="Confirm" variant="primary" isLoading={p.busy} onClick={p.onConfirmCode} />
              <Button label="Try another way" variant="ghost" onClick={p.onBackToPhone} />
            </VStack>
          )}
          {p.step === 2 && (
            <VStack gap={2} style={{ width: "100%" }}>
              <Text weight="semibold">Choose an account</Text>
              <List density="balanced">
                <ListItem label="Muse User" description="muse.user" isSelected onClick={() => {}} />
              </List>
              <Button label="Continue" variant="primary" isLoading={p.busy} onClick={p.onContinueAccount} />
            </VStack>
          )}
          {p.step === 3 && (
            <VStack gap={2} style={{ width: "100%" }}>
              <Text weight="semibold">Connectors</Text>
              <List density="balanced">
                {p.connectors.map((c) => (
                  <ListItem key={c.id} label={c.name}
                    description={p.linked.includes(c.id) ? "Linked" : "Not linked"}
                    isSelected={p.linked.includes(c.id)}
                    onClick={() => p.onToggleLink(c.id)} />
                ))}
              </List>
              <TextInput label="What should Muse call you?" value={p.name} onChange={p.onName} />
              <Button label="Continue" variant="primary" onClick={p.onContinueConnectors} />
            </VStack>
          )}
          {p.step === 4 && (
            <VStack gap={2} style={{ width: "100%" }}>
              <Text weight="semibold">Workspace</Text>
              <Text color="secondary">Provision the local offline VM, then set a PIN.</Text>
              <TextInput label="Set a 4-digit PIN" value={p.pin} onChange={p.onPin} placeholder="1111" />
              <Button label="Activate" variant="primary" isLoading={p.busy} onClick={p.onActivate} />
            </VStack>
          )}
          {p.step === 5 && (
            <VStack gap={2} style={{ width: "100%" }}>
              <Text weight="semibold">Before you get started</Text>
              <Text color="secondary">Muse works fully offline against the local demo service.</Text>
              <Button label="Accept and continue" variant="primary" isLoading={p.busy} onClick={p.onAcceptTos} />
            </VStack>
          )}
        </VStack>
      </VStack>
    </Center>
  );
}
